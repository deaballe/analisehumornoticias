class JornalDoComercioScraper < BaseScraper
  DEFAULT_FEEDS = [
    "https://www.jornaldocomercio.com/_conteudo/politica/rss.xml",
    "https://www.jornaldocomercio.com/_conteudo/economia/rss.xml"
  ].freeze

  def fetch
    urls = Array(@source.fetch_config["urls"].presence || @source.fetch_config["url"].presence || DEFAULT_FEEDS)

    urls.flat_map { |url| parse_rss(url) }
        .uniq { |item| item[:url] }
        .first(40)
  end
end
