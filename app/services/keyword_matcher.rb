class KeywordMatcher
  STOP_WORDS = %w[de da do das dos na no nas nos em a o e para por com].freeze

  def self.call(article, keywords)
    new(article, keywords).call
  end

  def initialize(article, keywords)
    @article = article
    @keywords = keywords
  end

  def call
    haystack = normalize("#{@article.title} #{@article.content_snippet}")
    @keywords.select do |keyword|
      terms = [ keyword.term, *Array(keyword.synonyms) ].map { |term| normalize(term) }
      terms.any? { |term| matches?(haystack, term) }
    end
  end

  private

  def normalize(text)
    text.to_s.downcase.tr("áàâãäéèêëíìîïóòôõöúùûüç", "aaaaaeeeeiiiiooooouuuuc")
  end

  def matches?(haystack, term)
    return false if term.blank?

    words = significant_words(term)
    return false if words.empty?

    if words.size > 1
      words.all? { |word| includes_word?(haystack, word) }
    else
      includes_word?(haystack, words.first)
    end
  end

  def significant_words(term)
    term.split(/\s+/).reject { |word| STOP_WORDS.include?(word) }.presence || term.split(/\s+/)
  end

  def includes_word?(haystack, word)
    return false if word.blank?

    if word.length <= 3
      haystack.match?(/\b#{Regexp.escape(word)}\b/)
    else
      haystack.include?(word)
    end
  end
end
