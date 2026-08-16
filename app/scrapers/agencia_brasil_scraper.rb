class AgenciaBrasilScraper < BaseScraper
  # Avoid bare \bRS\b — too many false positives in national feeds (e.g. sports).
  RS_PATTERN = /rio grande do sul|porto alegre|ga[uú]ch[oa]|governo do rs|\brs\b[,)]|\/rs\/|, rs\b/i

  def fetch
    parse_rss(@source.fetch_config.fetch("url")).select do |item|
      text = "#{item[:title]} #{item[:content_snippet]}"
      text.match?(RS_PATTERN)
    end
  end
end
