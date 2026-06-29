class NewsPipeline
  def initialize(slot:)
    @slot = slot
    @snapshot_date = Time.zone.today
    @keywords = Keyword.order(:term).to_a
  end

  def run
    articles = collect
    analyses = analyze(articles)
    aggregate(analyses)
    BriefingGenerator.call(analyses: analyses, snapshot_date: @snapshot_date, slot: @slot)
    analyses
  end

  def collect
    Source.find_each.flat_map do |source|
      collect_from_source(source)
    rescue StandardError => e
      Rails.logger.error("Collection failed for #{source.slug}: #{e.message}")
      []
    end
  end

  private

  def collect_from_source(source)
    scraper_class = ScraperRegistry.for(source)
    items = scraper_class.call(source)

    items.filter_map do |item|
      Article.find_or_create_by!(url: item[:url]) do |article|
        article.source = source
        article.title = item[:title]
        article.published_at = item[:published_at]
        article.content_snippet = item[:content_snippet]
      end
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end

  def analyze(articles)
    duplicate_counts = duplicate_title_counts(articles)
    analyses = []

    articles.each do |article|
      matched_keywords = KeywordMatcher.call(article, @keywords)
      next if matched_keywords.empty?

      matched_keywords.each do |keyword|
        sentiments = SentimentAnalyzer.call(article: article, keyword: keyword)
        score = RelevanceScorer.call(
          article: article,
          keyword: keyword,
          sentiment_institutional: sentiments[:sentiment_institutional],
          sentiment_thematic: sentiments[:sentiment_thematic],
          duplicate_count: duplicate_counts[normalized_title(article.title)] || 1
        )

        analysis = ArticleAnalysis.find_or_initialize_by(article: article, keyword: keyword)
        analysis.assign_attributes(sentiments.merge(relevance_score: score))
        analysis.save!
        analyses << analysis
      end
    end

    analyses
  end

  def aggregate(analyses)
    @keywords.each do |keyword|
      keyword_analyses = analyses.select { |analysis| analysis.keyword_id == keyword.id }
      SnapshotAggregator.call(
        keyword: keyword,
        analyses: keyword_analyses,
        snapshot_date: @snapshot_date,
        slot: @slot
      )
    end
  end

  def duplicate_title_counts(articles)
    articles.group_by { |article| normalized_title(article.title) }.transform_values(&:count)
  end

  def normalized_title(title)
    title.to_s.downcase.gsub(/\s+/, " ").strip
  end
end
