class CorreioDoPovoScraper < BaseScraper
  LIST_URL = "https://www.correiodopovo.com.br/not%C3%ADcias/pol%C3%ADtica".freeze

  def fetch
    parse_html_listing(
      page_url: @source.fetch_config.fetch("url", LIST_URL),
      link_pattern: %r{/not%C3%ADcias/pol%C3%ADtica/.+1\.\d+$|/notícias/política/.+1\.\d+$}
    )
  end
end
