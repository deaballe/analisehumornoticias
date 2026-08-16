class SnapshotAggregator
  CRITICAL_NEGATIVE_THRESHOLD = 60.0
  HIGH_IMPACT_SCORE = 70
  POSITIVE_BAND = 0..33
  NEUTRAL_BAND = 34..66

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
    scores = @analyses.map { |analysis| HumorScore.call(analysis) }
    total = scores.size
    median_humor = HumorScore.median(@analyses)
    median_relevance = median_of(@analyses.map(&:relevance_score))

    bands = band_percentages(scores, total)

    DailySnapshot.find_or_initialize_by(
      snapshot_date: @snapshot_date,
      slot: @slot,
      keyword: @keyword
    ).tap do |snapshot|
      snapshot.assign_attributes(
        # pct_negative = median humor index (0 positive → 100 negative) for cards/chart.
        pct_negative: median_humor,
        median_relevance: median_relevance,
        # pct_positive / pct_neutral = share of articles in each humor band.
        pct_positive: bands[:positive],
        pct_neutral: bands[:neutral],
        article_count: total,
        is_critical: critical?(median_humor, total)
      )
      snapshot.save!
    end
  end

  private

  def median_of(values)
    scores = Array(values).map(&:to_f).sort
    return 0.0 if scores.empty?

    mid = scores.length / 2
    if scores.length.odd?
      scores[mid]
    else
      ((scores[mid - 1] + scores[mid]) / 2.0).round(2)
    end
  end

  def band_percentages(scores, total)
    return { positive: 0.0, neutral: 0.0, negative: 0.0 } if total.zero?

    positive = scores.count { |score| POSITIVE_BAND.cover?(score.round) }
    neutral = scores.count { |score| NEUTRAL_BAND.cover?(score.round) }
    negative = total - positive - neutral

    {
      positive: (positive * 100.0 / total).round(2),
      neutral: (neutral * 100.0 / total).round(2),
      negative: (negative * 100.0 / total).round(2)
    }
  end

  def critical?(median_negative, total)
    return false if total.zero?

    volume_critical = median_negative >= CRITICAL_NEGATIVE_THRESHOLD
    impact_critical = @analyses.any? do |analysis|
      analysis.relevance_score >= HIGH_IMPACT_SCORE &&
        analysis.sentiment_institutional == "negative" &&
        analysis.sentiment_thematic == "negative"
    end

    volume_critical || impact_critical
  end
end
