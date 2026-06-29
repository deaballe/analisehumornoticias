class AnpScraper < BaseScraper
  def fetch
    body = fetch_body(@source.base_url)
    doc = Nokogiri::HTML(body)

    doc.css("article a, .news-item a, h2 a, h3 a").filter_map do |link|
      title = link.text.to_s.strip
      href = link["href"].to_s.strip
      next if title.blank? || href.blank?

      url = href.start_with?("http") ? href : URI.join(@source.base_url, href).to_s
      {
        title: title,
        url: url,
        published_at: Time.current,
        content_snippet: title
      }
    end.uniq { |item| item[:url] }.first(30)
  end
end
