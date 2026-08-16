class ZeroHoraScraper < BaseScraper
  LIST_URL = "https://gauchazh.clicrbs.com.br/politica/ultimas-noticias/".freeze
  LINK_PATTERN = %r{/politica/noticia/}i

  def fetch
    parse_html_listing(
      page_url: @source.fetch_config.fetch("url", LIST_URL),
      link_pattern: LINK_PATTERN,
      base_url: "https://gauchazh.clicrbs.com.br",
      limit: 40
    )
  end
end
