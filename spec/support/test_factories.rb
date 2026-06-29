module TestFactories
  def create_test_source(slug: nil)
    Source.create!(
      slug: slug || "test-source-#{SecureRandom.hex(4)}",
      name: "Test Source",
      base_url: "https://example.com",
      fetch_type: "rss",
      fetch_config: { url: "https://example.com/feed" }
    )
  end

  def create_test_keyword(term: nil, synonyms: [])
    Keyword.create!(
      term: term || "test-keyword-#{SecureRandom.hex(4)}",
      synonyms: synonyms
    )
  end
end

RSpec.configure do |config|
  config.include TestFactories
end
