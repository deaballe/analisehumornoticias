require "rails_helper"

RSpec.describe AttentionScore do
  def analysis(attrs)
    ArticleAnalysis.new(
      sentiment_institutional: "neutral",
      sentiment_thematic: "neutral",
      relevance_score: 50,
      **attrs
    )
  end

  it "averages humor and relevance" do
    # humor = (0 + 100) / 2 = 50; attention = (50 + 60) / 2 = 55
    record = analysis(
      sentiment_institutional: "positive",
      sentiment_thematic: "negative",
      relevance_score: 60
    )
    expect(AttentionScore.call(record)).to eq(55.0)
  end

  it "adds a bonus when institutional sentiment is negative" do
    # humor = 100; attention = (100 + 50) / 2 + 20 = 95
    record = analysis(
      sentiment_institutional: "negative",
      sentiment_thematic: "negative",
      relevance_score: 50
    )
    expect(AttentionScore.call(record)).to eq(95.0)
  end

  it "ranks institutional problems above high-relevance operational stories" do
    operational = analysis(
      sentiment_institutional: "positive",
      sentiment_thematic: "negative",
      relevance_score: 60
    )
    institutional = analysis(
      sentiment_institutional: "negative",
      sentiment_thematic: "negative",
      relevance_score: 50
    )

    expect(AttentionScore.call(institutional)).to be > AttentionScore.call(operational)
  end
end
