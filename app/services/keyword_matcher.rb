class KeywordMatcher
  STOP_WORDS = %w[de da do das dos na no nas nos em a o e para por com].freeze
  MAX_GAP_WORDS = 3

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
      matches_near?(haystack, words)
    else
      includes_word?(haystack, words.first)
    end
  end

  def significant_words(term)
    term.split(/\s+/).reject { |word| STOP_WORDS.include?(word) }.presence || term.split(/\s+/)
  end

  def matches_near?(haystack, words)
    matches_ordered_near?(haystack, words) ||
      (words.size == 2 && matches_ordered_near?(haystack, words.reverse))
  end

  def matches_ordered_near?(haystack, words)
    parts = words.map { |word| "(?:#{word_variants(word).map { |variant| Regexp.escape(variant) }.join("|")})" }
    gap = "(?:\\W+\\w+){0,#{MAX_GAP_WORDS}}\\W+"
    haystack.match?(/\b#{parts.join(gap)}\b/)
  end

  def includes_word?(haystack, word)
    return false if word.blank?

    word_variants(word).any? do |variant|
      haystack.match?(/\b#{Regexp.escape(variant)}\b/)
    end
  end

  def word_variants(word)
    variants = [ word ]

    unless word.end_with?("s")
      variants << "#{word}s"
      variants << "#{word}es"
    end

    if word.end_with?("es") && word.length > 5
      variants << word.delete_suffix("es")
    elsif word.end_with?("s") && word.length > 4
      variants << word.delete_suffix("s")
    end

    variants.uniq
  end
end
