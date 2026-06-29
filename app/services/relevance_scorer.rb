class RelevanceScorer
  def self.call(article:, keyword:, sentiment_institutional:, sentiment_thematic:, duplicate_count: 1)
    new(
      article: article,
      keyword: keyword,
      sentiment_institutional: sentiment_institutional,
      sentiment_thematic: sentiment_thematic,
      duplicate_count: duplicate_count
    ).score
  end

  def initialize(article:, keyword:, sentiment_institutional:, sentiment_thematic:, duplicate_count:)
    @article = article
    @keyword = keyword
    @sentiment_institutional = sentiment_institutional
    @sentiment_thematic = sentiment_thematic
    @duplicate_count = duplicate_count
  end

  def score
    [
      recency_score,
      title_match_score,
      cross_source_score,
      negative_magnitude_score
    ].sum.round.clamp(0, 100)
  end

  private

  def recency_score
    published_at = @article.published_at || Time.current
    hours = ((Time.current - published_at) / 1.hour).clamp(0, 48)
    ((1 - (hours / 48.0)) * 25).round
  end

  def title_match_score
    title = @article.title.to_s.downcase
    terms = [ @keyword.term, *Array(@keyword.synonyms) ].map(&:downcase)
    terms.any? { |term| title.include?(term) } ? 25 : 0
  end

  def cross_source_score
    @duplicate_count >= 2 ? 25 : 0
  end

  def negative_magnitude_score
    institutional = @sentiment_institutional == "negative" ? 12.5 : 0
    thematic = @sentiment_thematic == "negative" ? 12.5 : 0
    institutional + thematic
  end
end
