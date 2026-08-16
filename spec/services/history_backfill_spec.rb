require "rails_helper"

RSpec.describe HistoryBackfill do
  it "builds snapshots across the window from published_at dates" do
    keyword = create_test_keyword(term: "polícia civil backfill", synonyms: [ "policia civil" ])
    source = create_test_source

    older = Article.create!(
      source: source,
      title: "Polícia Civil prende suspeito em operação",
      url: "https://example.com/older-#{SecureRandom.hex(4)}",
      published_at: 3.days.ago,
      content_snippet: "Polícia Civil concluiu prisão"
    )
    today = Article.create!(
      source: source,
      title: "Polícia Civil investiga novo caso",
      url: "https://example.com/today-#{SecureRandom.hex(4)}",
      published_at: Time.zone.now,
      content_snippet: "Polícia Civil abre inquérito"
    )

    [ older, today ].each do |article|
      ArticleAnalysis.create!(
        article: article,
        keyword: keyword,
        sentiment_institutional: "negative",
        sentiment_thematic: "negative",
        relevance_score: 70
      )
    end

    result = described_class.call(days: 7, slot: "manha", collect: false, analyze: false, fill_gaps: false)

    expect(result[:snapshots]).to be >= Keyword.count
    older_snap = DailySnapshot.find_by(keyword: keyword, snapshot_date: 3.days.ago.to_date, slot: "manha")
    today_snap = DailySnapshot.find_by(keyword: keyword, snapshot_date: Time.zone.today, slot: "manha")
    expect(older_snap.article_count).to eq(1)
    expect(today_snap.article_count).to eq(1)
  end

  it "fills empty days when fill_gaps is enabled" do
    keyword = create_test_keyword(term: "brigada militar backfill", synonyms: [ "brigada militar" ])
    source = create_test_source
    article = Article.create!(
      source: source,
      title: "Brigada Militar prende suspeitos",
      url: "https://example.com/bm-#{SecureRandom.hex(4)}",
      published_at: Time.zone.now,
      content_snippet: "Brigada Militar em ação"
    )
    ArticleAnalysis.create!(
      article: article,
      keyword: keyword,
      sentiment_institutional: "negative",
      sentiment_thematic: "negative",
      relevance_score: 65
    )

    described_class.call(days: 7, slot: "manha", collect: false, analyze: false, fill_gaps: true)

    days_with_coverage = DailySnapshot.where(keyword: keyword, slot: "manha")
                                      .where("article_count > 0")
                                      .distinct
                                      .count(:snapshot_date)
    expect(days_with_coverage).to be >= 2
  end
end
