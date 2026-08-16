# Maps dual categorical sentiments to a continuous humor index.
# 0 = fully positive, 50 = neutral, 100 = fully negative.
class HumorScore
  SENTIMENT_POINTS = {
    "positive" => 0,
    "neutral" => 50,
    "negative" => 100
  }.freeze

  def self.call(analysis)
    new(analysis).call
  end

  def self.median(analyses)
    scores = Array(analyses).map { |analysis| call(analysis) }.sort
    return 0.0 if scores.empty?

    mid = scores.length / 2
    if scores.length.odd?
      scores[mid].to_f
    else
      ((scores[mid - 1] + scores[mid]) / 2.0).round(2)
    end
  end

  def initialize(analysis)
    @analysis = analysis
  end

  def call
    institutional = points(@analysis.sentiment_institutional)
    thematic = points(@analysis.sentiment_thematic)
    ((institutional + thematic) / 2.0).round(2)
  end

  private

  def points(sentiment)
    SENTIMENT_POINTS.fetch(sentiment.to_s, 50)
  end
end
