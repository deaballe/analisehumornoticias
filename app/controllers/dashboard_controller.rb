class DashboardController < ApplicationController
  def index
    @briefing = DailyBriefing.current
    @latest_slot = latest_slot
    @tema_snapshots = snapshots_for(@latest_slot, section: "temas")
    @spgg_snapshots = snapshots_for(@latest_slot, section: "spgg_equipe")
    @section_meta = SeedKeywords::SECTIONS
    @trend_data = trend_data
    @updated_at = updated_at_label
  end

  private

  def latest_slot
    return nil unless @briefing

    { date: @briefing.briefing_date, slot: @briefing.slot }
  end

  def snapshots_for(latest_slot, section:)
    keywords = Keyword.where(section: section).ordered

    unless latest_slot
      return keywords.map { |keyword| placeholder_snapshot(keyword) }
    end

    snapshots_by_keyword = DailySnapshot.includes(:keyword)
                                        .where(snapshot_date: latest_slot[:date], slot: latest_slot[:slot])
                                        .where(keywords: { section: section })
                                        .index_by(&:keyword_id)

    keywords.map { |keyword| snapshots_by_keyword[keyword.id] || placeholder_snapshot(keyword) }
  end

  def placeholder_snapshot(keyword)
    DailySnapshot.new(
      keyword: keyword,
      pct_positive: 0,
      pct_neutral: 0,
      pct_negative: 0,
      median_relevance: 0,
      article_count: 0,
      is_critical: false
    )
  end

  def trend_data
    dates = DailySnapshot.where("article_count > 0")
                         .distinct
                         .order(:snapshot_date)
                         .pluck(:snapshot_date)
                         .last(7)
    return [] if dates.empty?

    keyword_ids = DailySnapshot.where(snapshot_date: dates)
                               .where("article_count > 0")
                               .distinct
                               .pluck(:keyword_id)
    return [] if keyword_ids.empty?

    analyses_by_keyword = ArticleAnalysis
                          .includes(:keyword)
                          .where(keyword_id: keyword_ids)
                          .group_by(&:keyword)

    rows = analyses_by_keyword.filter_map do |keyword, rows|
      next if rows.empty?

      {
        term: helpers.display_keyword_term(keyword.term),
        humor: HumorScore.median(rows),
        relevance: median_relevance(rows)
      }
    end

    rows.sort_by! { |row| [ -row[:humor], row[:term] ] }

    [
      { name: "Humor mediano", data: rows.map { |row| [ row[:term], row[:humor] ] } },
      { name: "Relevância mediana", data: rows.map { |row| [ row[:term], row[:relevance] ] } }
    ]
  end

  def median_relevance(analyses)
    scores = analyses.map(&:relevance_score).sort
    return 0.0 if scores.empty?

    mid = scores.length / 2
    if scores.length.odd?
      scores[mid].to_f
    else
      ((scores[mid - 1] + scores[mid]) / 2.0).round(2)
    end
  end

  def updated_at_label
    return "Sem dados" unless @briefing

    slot_label = @briefing.slot == "manha" ? "07:00" : "18:00"
    "#{@briefing.briefing_date.strftime('%d/%m/%Y')} #{slot_label}"
  end
end
