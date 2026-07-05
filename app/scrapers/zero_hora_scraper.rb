class ZeroHoraScraper < BaseScraper
  LIST_URL = "https://gauchazh.clicrbs.com.br/porto-alegre/ultimas-noticias/".freeze

  def fetch
    parse_html_listing(
      page_url: @source.fetch_config.fetch("url", LIST_URL),
      link_pattern: %r{/noticia/},
      base_url: "https://gauchazh.clicrbs.com.br"
    )
  end
end
