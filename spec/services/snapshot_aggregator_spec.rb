require "rails_helper"

RSpec.describe SnapshotAggregator do
  let(:keyword) { create_test_keyword(term: "ppp snapshot teste") }
  let(:source) { create_test_source }

  def build_analysis(title:, institutional:, thematic:, score:)
    article = Article.create!(
      source: source,
      title: title,
      url: "https://example.com/#{SecureRandom.hex(6)}",
      published_at: Time.current,
      content_snippet: "Resumo"
    )

    ArticleAnalysis.create!(
      article: article,
      keyword: keyword,
      sentiment_institutional: institutional,
      sentiment_thematic: thematic,
      relevance_score: score
    )
  end

  it "marks snapshot critical when negative volume reaches 60%" do
    analyses = Array.new(3) do |index|
      build_analysis(title: "Negativa #{index}", institutional: "negative", thematic: "negative", score: 40)
    end
    analyses << build_analysis(title: "Neutra", institutional: "neutral", thematic: "neutral", score: 20)
    analyses << build_analysis(title: "Positiva", institutional: "positive", thematic: "positive", score: 10)

    snapshot = described_class.call(
      keyword: keyword,
      analyses: analyses,
      snapshot_date: Date.current,
      slot: "manha"
    )

    expect(snapshot.pct_negative.to_f).to eq(60.0)
    expect(snapshot.is_critical).to be(true)
  end

  it "marks snapshot critical for high impact dual-negative article" do
    analyses = [
      build_analysis(title: "Impacto", institutional: "negative", thematic: "negative", score: 75)
    ]

    snapshot = described_class.call(
      keyword: keyword,
      analyses: analyses,
      snapshot_date: Date.current,
      slot: "tarde"
    )

    expect(snapshot.is_critical).to be(true)
  end
end
