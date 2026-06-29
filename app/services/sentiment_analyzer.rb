class SentimentAnalyzer
  MAX_RETRIES = 2
  FALLBACK = { sentiment_institutional: "neutral", sentiment_thematic: "neutral" }.freeze

  def self.call(article:, keyword:)
    new(article: article, keyword: keyword).call
  end

  def initialize(article:, keyword:)
    @article = article
    @keyword = keyword
  end

  def call
    return FALLBACK if ENV["DEEPSEEK_API_KEY"].blank?

    MAX_RETRIES.times do |attempt|
      result = request_sentiment
      return result if result
    rescue StandardError => e
      Rails.logger.warn("SentimentAnalyzer attempt #{attempt + 1} failed: #{e.message}")
    end

    FALLBACK
  end

  private

  def request_sentiment
    response = DEEPSEEK_CLIENT.chat(
      parameters: {
        model: ENV.fetch("DEEPSEEK_MODEL", "deepseek-chat"),
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: "Classifique sentimento em JSON com chaves sentiment_institutional e sentiment_thematic (positive, neutral ou negative)."
          },
          {
            role: "user",
            content: <<~PROMPT
              Keyword: #{@keyword.term}
              Manchete: #{@article.title}
              Contexto: #{@article.content_snippet}
            PROMPT
          }
        ]
      }
    )

    payload = JSON.parse(response.dig("choices", 0, "message", "content"))
    institutional = payload["sentiment_institutional"]
    thematic = payload["sentiment_thematic"]

    return nil unless ArticleAnalysis::SENTIMENTS.include?(institutional)
    return nil unless ArticleAnalysis::SENTIMENTS.include?(thematic)

    {
      sentiment_institutional: institutional,
      sentiment_thematic: thematic
    }
  end
end
