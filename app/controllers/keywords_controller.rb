class KeywordsController < ApplicationController
  def show
    @keyword = Keyword.find(params[:id])
    @briefing = DailyBriefing.current
    @snapshot = current_snapshot
    @analyses = current_analyses
    @median_humor = HumorScore.median(@analyses)
  end

  private

  def current_snapshot
    return nil unless @briefing

    DailySnapshot.find_by(
      keyword: @keyword,
      snapshot_date: @briefing.briefing_date,
      slot: @briefing.slot
    )
  end

  def current_analyses
    # Show every matched analysis for this keyword. The card's article_count is
    # built from the same set on the current day; filtering by updated_at hid
    # valid matérias after backfills/re-runs.
    ArticleAnalysis.includes(article: :source)
                   .joins(:article)
                   .where(keyword: @keyword)
                   .order(Arel.sql("COALESCE(articles.published_at, articles.created_at) DESC"), relevance_score: :desc, id: :desc)
  end
end
