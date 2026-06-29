require "rails_helper"

RSpec.describe SentimentAnalyzer do
  let(:source) { create_test_source }
  let(:keyword) { create_test_keyword(term: "tema sentimento teste") }
  let(:article) do
    Article.create!(
      source: source,
      title: "Noticia sobre tema sentimento teste",
      url: "https://example.com/#{SecureRandom.hex(4)}",
      content_snippet: "Resumo"
    )
  end

  it "returns neutral fallback when API key is missing" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("DEEPSEEK_API_KEY").and_return(nil)

    result = described_class.call(article: article, keyword: keyword)
    expect(result).to eq(sentiment_institutional: "neutral", sentiment_thematic: "neutral")
  end

  it "parses deepseek json response" do
    client = instance_double(OpenAI::Client)
    stub_const("DEEPSEEK_CLIENT", client)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("DEEPSEEK_API_KEY").and_return("test-key")
    allow(ENV).to receive(:fetch).and_call_original
    allow(client).to receive(:chat).and_return(
      "choices" => [
        {
          "message" => {
            "content" => {
              sentiment_institutional: "negative",
              sentiment_thematic: "neutral"
            }.to_json
          }
        }
      ]
    )

    result = described_class.call(article: article, keyword: keyword)
    expect(result[:sentiment_institutional]).to eq("negative")
    expect(result[:sentiment_thematic]).to eq("neutral")
  end
end
