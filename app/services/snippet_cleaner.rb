class SnippetCleaner
  def self.call(raw)
    new(raw).call
  end

  def initialize(raw)
    @raw = raw.to_s
  end

  def call
    text = Nokogiri::HTML.fragment(@raw).text
    CGI.unescapeHTML(text).gsub(/\u00a0/, " ").gsub(/\s+/, " ").strip
  end
end
