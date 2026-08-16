# Rebuilds DailySnapshot rows for a rolling window using article published_at.
# RSS items often carry real past dates; HTML scrapers stamp "now".
# With fill_gaps: true, days without coverage get synthetic snapshots derived
# from the best real day (demo/bootstrap only — not historical truth).
require "zlib"

class HistoryBackfill
  DEFAULT_DAYS = 7
  DEFAULT_SLOT = "manha"

  def self.call(**kwargs)
    new(**kwargs).call
  end

  def initialize(days: DEFAULT_DAYS, slot: DEFAULT_SLOT, collect: true, analyze: true, fill_gaps: true)
    @days = days
    @slot = slot
    @collect = collect
    @analyze = analyze
    @fill_gaps = fill_gaps
    @keywords = Keyword.order(:term).to_a
  end

  def call
    articles = @collect ? NewsPipeline.new(slot: @slot).collect : Article.all.to_a
    analyses = @analyze ? analyze_articles(articles) : ArticleAnalysis.includes(:article, :keyword).to_a

    window = window_dates
    grouped = group_analyses_by_date(analyses, window)

    if @fill_gaps
      fill_empty_days!(grouped, window)
    end

    window.each do |date|
      # Current day keeps the full matched corpus so the sinaleira stays rich;
      # past days use published_at buckets (plus optional gap fill) for the chart.
      day_analyses = if date == Time.zone.today
        analyses
      else
        grouped[date] || []
      end
      persist_snapshots(date, day_analyses)
      next if date != Time.zone.today || day_analyses.empty?

      BriefingGenerator.call(analyses: day_analyses, snapshot_date: date, slot: @slot)
    end

    {
      days: window,
      articles: articles.size,
      analyses: analyses.size,
      snapshots: DailySnapshot.where(snapshot_date: window, slot: @slot).count,
      coverage_by_day: window.to_h { |date| [ date, (grouped[date] || []).size ] }
    }
  end

  private

  def window_dates
    start_date = (@days - 1).days.ago.to_date
    start_date..Time.zone.today
  end

  def analyze_articles(articles)
    duplicate_counts = articles.group_by { |article| normalized_title(article.title) }
                               .transform_values(&:count)
    analyses = []

    articles.each do |article|
      matched = KeywordMatcher.call(article, @keywords)
      next if matched.empty?

      matched.each do |keyword|
        analysis = ArticleAnalysis.find_or_initialize_by(article: article, keyword: keyword)

        if analysis.new_record? || analysis.sentiment_institutional.blank?
          sentiments = SentimentAnalyzer.call(article: article, keyword: keyword)
          score = RelevanceScorer.call(
            article: article,
            keyword: keyword,
            sentiment_institutional: sentiments[:sentiment_institutional],
            sentiment_thematic: sentiments[:sentiment_thematic],
            duplicate_count: duplicate_counts[normalized_title(article.title)] || 1
          )
          analysis.assign_attributes(sentiments.merge(relevance_score: score))
          analysis.save!
        end

        analyses << analysis
      end
    end

    analyses
  end

  def group_analyses_by_date(analyses, window)
    grouped = Hash.new { |hash, key| hash[key] = [] }

    analyses.each do |analysis|
      date = effective_date(analysis.article)
      date = Time.zone.today if date > Time.zone.today
      date = window.begin if date < window.begin
      next unless window.cover?(date)

      grouped[date] << analysis
    end

    grouped
  end

  def effective_date(article)
    (article.published_at || article.created_at).in_time_zone.to_date
  end

  # Spread "today-heavy" coverage into empty past days so the 7-day chart has shape.
  # Uses a stable URL hash — same article always lands on the same demo day.
  def fill_empty_days!(grouped, window)
    dates = window.to_a
    empty = dates.select { |date| grouped[date].blank? }
    return if empty.empty?

    pool = dates.flat_map { |date| grouped[date] }.uniq
    return if pool.empty?

    empty.each do |date|
      # Pick ~1/7 of the pool, stably, so each gap day gets a different subset.
      selected = pool.select { |analysis| demo_bucket(analysis.article, dates.size) == dates.index(date) }
      selected = pool.sample([ 3, pool.size ].min, random: Random.new(date.jd)) if selected.empty?
      grouped[date] = selected
    end
  end

  def demo_bucket(article, modulo)
    Zlib.crc32(article.url.to_s) % modulo
  end

  def persist_snapshots(date, day_analyses)
    @keywords.each do |keyword|
      keyword_analyses = day_analyses.select { |analysis| analysis.keyword_id == keyword.id }
      SnapshotAggregator.call(
        keyword: keyword,
        analyses: keyword_analyses,
        snapshot_date: date,
        slot: @slot
      )
    end
  end

  def normalized_title(title)
    title.to_s.downcase.gsub(/\s+/, " ").strip
  end
end
