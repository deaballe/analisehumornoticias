class KeywordMatcher
  def self.call(article, keywords)
    new(article, keywords).call
  end

  def initialize(article, keywords)
    @article = article
    @keywords = keywords
  end

  def call
    haystack = "#{@article.title} #{@article.content_snippet}".downcase
    @keywords.select do |keyword|
      terms = [ keyword.term, *Array(keyword.synonyms) ].map(&:downcase)
      terms.any? { |term| haystack.include?(term) }
    end
  end
end
