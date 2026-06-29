class SnapshotAggregator
  CRITICAL_NEGATIVE_THRESHOLD = 60.0
  HIGH_IMPACT_SCORE = 70

  def self.call(keyword:, analyses:, snapshot_date:, slot:)
    new(keyword: keyword, analyses: analyses, snapshot_date: snapshot_date, slot: slot).call
  end

  def initialize(keyword:, analyses:, snapshot_date:, slot:)
    @keyword = keyword
    @analyses = analyses
    @snapshot_date = snapshot_date
    @slot = slot
  end

  def call
    counts = sentiment_counts
    total = counts.values.sum

    pct = if total.zero?
      { positive: 0, neutral: 0, negative: 0 }
    else
      {
        positive: (counts[:positive] * 100.0 / total).round(2),
        neutral: (counts[:neutral] * 100.0 / total).round(2),
        negative: (counts[:negative] * 100.0 / total).round(2)
      }
    end

    DailySnapshot.find_or_initialize_by(
      snapshot_date: @snapshot_date,
      slot: @slot,
      keyword: @keyword
    ).tap do |snapshot|
      snapshot.assign_attributes(
        pct_positive: pct[:positive],
        pct_neutral: pct[:neutral],
        pct_negative: pct[:negative],
        article_count: total,
        is_critical: critical?(pct[:negative], total)
      )
      snapshot.save!
    end
  end

  private

  def sentiment_counts
    @analyses.each_with_object({ positive: 0, neutral: 0, negative: 0 }) do |analysis, counts|
      sentiment = classify(analysis)
      counts[sentiment] += 1
    end
  end

  def classify(analysis)
    if analysis.sentiment_thematic == "negative" || analysis.sentiment_institutional == "negative"
      :negative
    elsif analysis.sentiment_thematic == "positive" && analysis.sentiment_institutional == "positive"
      :positive
    else
      :neutral
    end
  end

  def critical?(pct_negative, total)
    return false if total.zero?

    volume_critical = pct_negative >= CRITICAL_NEGATIVE_THRESHOLD
    impact_critical = @analyses.any? do |analysis|
      analysis.relevance_score >= HIGH_IMPACT_SCORE &&
        analysis.sentiment_institutional == "negative" &&
        analysis.sentiment_thematic == "negative"
    end

    volume_critical || impact_critical
  end
end
