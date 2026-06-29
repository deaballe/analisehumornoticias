class KeywordsController < ApplicationController
  def show
    @keyword = Keyword.find(params[:id])
    @briefing = DailyBriefing.current
    @snapshot = current_snapshot
    @analyses = current_analyses
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
    return ArticleAnalysis.none unless @briefing

    ArticleAnalysis.includes(article: :source)
                   .joins(:article)
                   .where(keyword: @keyword)
                   .where("articles.created_at >= ?", cycle_start)
                   .order(relevance_score: :desc)
  end

  def cycle_start
    if @briefing.slot == "manha"
      @briefing.briefing_date.beginning_of_day + 7.hours
    else
      @briefing.briefing_date.beginning_of_day + 18.hours
    end
  end
end
