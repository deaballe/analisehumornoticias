class AgenciaBrasilScraper < BaseScraper
  RS_PATTERN = /rio grande do sul|\brs\b/i

  def fetch
    parse_rss(@source.fetch_config.fetch("url")).select do |item|
      text = "#{item[:title]} #{item[:content_snippet]}"
      text.match?(RS_PATTERN)
    end
  end
end
