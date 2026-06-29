class G1RsScraper < BaseScraper
  def fetch
    parse_rss(@source.fetch_config.fetch("url"))
  end
end
