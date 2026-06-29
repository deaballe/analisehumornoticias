class BriefingGenerator
  TOP_COUNT = 3

  def self.call(analyses:, snapshot_date:, slot:)
    new(analyses: analyses, snapshot_date: snapshot_date, slot: slot).call
  end

  def initialize(analyses:, snapshot_date:, slot:)
    @analyses = analyses
    @snapshot_date = snapshot_date
    @slot = slot
  end

  def call
    items = top_analyses.map { |analysis| build_item(analysis) }

    DailyBriefing.find_or_initialize_by(
      briefing_date: @snapshot_date,
      slot: @slot
    ).tap do |briefing|
      briefing.items = items
      briefing.save!
    end
  end

  private

  def top_analyses
    @analyses.sort_by { |analysis| -analysis.relevance_score }.first(TOP_COUNT)
  end

  def build_item(analysis)
    {
      article_id: analysis.article_id,
      title: analysis.article.title,
      url: analysis.article.url,
      source: analysis.article.source.name,
      relevance_score: analysis.relevance_score,
      summary: generate_summary(analysis)
    }
  end

  def generate_summary(analysis)
    return fallback_summary(analysis) if ENV["DEEPSEEK_API_KEY"].blank?

    response = DEEPSEEK_CLIENT.chat(
      parameters: {
        model: ENV.fetch("DEEPSEEK_MODEL", "deepseek-chat"),
        messages: [
          {
            role: "system",
            content: "Resuma a notícia em 2-3 frases objetivas em português do Brasil."
          },
          {
            role: "user",
            content: <<~PROMPT
              Título: #{analysis.article.title}
              Contexto: #{analysis.article.content_snippet}
              Keyword: #{analysis.keyword.term}
            PROMPT
          }
        ]
      }
    )

    response.dig("choices", 0, "message", "content").presence || fallback_summary(analysis)
  rescue StandardError => e
    Rails.logger.warn("BriefingGenerator summary failed: #{e.message}")
    fallback_summary(analysis)
  end

  def fallback_summary(analysis)
    snippet = analysis.article.content_snippet.to_s.strip
    snippet.presence || analysis.article.title
  end
end
