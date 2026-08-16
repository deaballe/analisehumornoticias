# Ranks how urgently a story should be looked at in the Top 3 briefing.
# Combines humor (worse tone → higher) and relevance, with a boost when the
# institutional lens is negative (problem framed around government/State).
class AttentionScore
  INSTITUTIONAL_BONUS = 20.0

  def self.call(analysis)
    new(analysis).call
  end

  def initialize(analysis)
    @analysis = analysis
  end

  def call
    humor = HumorScore.call(@analysis)
    relevance = @analysis.relevance_score.to_f
    score = (humor + relevance) / 2.0
    score += INSTITUTIONAL_BONUS if @analysis.sentiment_institutional == "negative"
    score.round(2)
  end
end
