class ZeroHoraScraper < BaseScraper
  def fetch
    parse_rss(@source.fetch_config.fetch("url"))
  end
end
