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

  it "stores median humor index instead of categorical negative share" do
    analyses = [
      build_analysis(title: "Negativa 1", institutional: "negative", thematic: "negative", score: 40), # 100
      build_analysis(title: "Negativa 2", institutional: "negative", thematic: "negative", score: 40), # 100
      build_analysis(title: "Negativa 3", institutional: "negative", thematic: "negative", score: 40), # 100
      build_analysis(title: "Neutra", institutional: "neutral", thematic: "neutral", score: 20), # 50
      build_analysis(title: "Positiva", institutional: "positive", thematic: "positive", score: 10) # 0
    ]
    # sorted scores: 0, 50, 100, 100, 100 → median 100

    snapshot = described_class.call(
      keyword: keyword,
      analyses: analyses,
      snapshot_date: Date.current,
      slot: "manha"
    )

    expect(snapshot.pct_negative.to_f).to eq(100.0)
    expect(snapshot.median_relevance.to_f).to eq(40.0)
    expect(snapshot.pct_positive.to_f).to eq(20.0) # 1/5 in positive band
    expect(snapshot.pct_neutral.to_f).to eq(20.0) # 1/5 neutral band
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
    expect(snapshot.pct_negative.to_f).to eq(100.0)
  end

  it "uses median 50 for balanced positive and negative pair" do
    analyses = [
      build_analysis(title: "Boa", institutional: "positive", thematic: "positive", score: 10),
      build_analysis(title: "Ruim", institutional: "negative", thematic: "negative", score: 10)
    ]

    snapshot = described_class.call(
      keyword: keyword,
      analyses: analyses,
      snapshot_date: Date.current,
      slot: "manha"
    )

    expect(snapshot.pct_negative.to_f).to eq(50.0)
    expect(snapshot.is_critical).to be(false)
  end
end
