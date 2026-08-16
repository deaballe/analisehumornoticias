require "rails_helper"

RSpec.describe HumorScore do
  def analysis(institutional:, thematic:)
    ArticleAnalysis.new(
      sentiment_institutional: institutional,
      sentiment_thematic: thematic
    )
  end

  it "scores dual-negative as 100" do
    expect(described_class.call(analysis(institutional: "negative", thematic: "negative"))).to eq(100.0)
  end

  it "scores dual-positive as 0" do
    expect(described_class.call(analysis(institutional: "positive", thematic: "positive"))).to eq(0.0)
  end

  it "scores mixed positive/negative as 50" do
    expect(described_class.call(analysis(institutional: "positive", thematic: "negative"))).to eq(50.0)
  end

  it "returns the median humor across analyses" do
    analyses = [
      analysis(institutional: "positive", thematic: "positive"), # 0
      analysis(institutional: "negative", thematic: "negative"), # 100
      analysis(institutional: "neutral", thematic: "neutral") # 50
    ]
    expect(described_class.median(analyses)).to eq(50.0)
  end
end
