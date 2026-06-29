require "rails_helper"

RSpec.describe RelevanceScorer do
  let(:source) { create_test_source }
  let(:keyword) { create_test_keyword(term: "gestao eficiente rs", synonyms: [ "eficiencia" ]) }
  let(:article) do
    Article.create!(
      source: source,
      title: "Estado apresenta gestao eficiente rs",
      url: "https://example.com/#{SecureRandom.hex(4)}",
      published_at: 1.hour.ago,
      content_snippet: "Resumo"
    )
  end

  it "returns high score for recent dual-negative title match" do
    score = described_class.call(
      article: article,
      keyword: keyword,
      sentiment_institutional: "negative",
      sentiment_thematic: "negative",
      duplicate_count: 2
    )

    expect(score).to be >= 70
  end
end
