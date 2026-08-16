class BaseScraper
  USER_AGENT = "Mozilla/5.0 (compatible; HumorEcossistemaRS/1.0; +https://github.com/deaballe/analisehumornoticias)".freeze
  REQUEST_DELAY = 2
  REDIRECT_STATUSES = [ 301, 302, 303, 307, 308 ].freeze

  def self.call(source)
    new(source).fetch
  end

  def initialize(source)
    @source = source
  end

  def fetch
    raise NotImplementedError
  end

  private

  def http_client
    @http_client ||= Faraday.new do |client|
      client.headers["User-Agent"] = USER_AGENT
      client.options.timeout = 15
    end
  end

  def fetch_body(url, redirect_limit: 5)
    sleep REQUEST_DELAY unless Rails.env.test?
    response = http_client.get(url)

    if REDIRECT_STATUSES.include?(response.status)
      raise "Too many redirects for #{url}" if redirect_limit.zero?

      location = response.headers["location"]
      raise "Redirect without location for #{url}" if location.blank?

      next_url = location.start_with?("http") ? location : URI.join(url, location).to_s
      return fetch_body(next_url, redirect_limit: redirect_limit - 1)
    end

    raise "HTTP #{response.status} for #{url}" unless response.success?

    response.body
  end

  def parse_rss(url)
    body = fetch_body(url)
    body = body.gsub(/xmlns:media="[^"]+"xmlns:media="/, 'xmlns:media="')
    feed = Feedjira.parse(body)

    feed.entries.map do |entry|
      {
        title: entry.title.to_s.strip,
        url: entry.url.to_s.strip,
        published_at: entry.published || entry.updated,
        content_snippet: SnippetCleaner.call(entry.summary).truncate(500)
      }
    end.reject { |item| item[:title].blank? || item[:url].blank? }
  end

  def parse_html_listing(page_url:, link_pattern:, base_url: nil, limit: 30)
    items = scrape_html_listing(page_url: page_url, link_pattern: link_pattern, base_url: base_url, limit: limit)
    return items if items.any?

    sleep REQUEST_DELAY unless Rails.env.test?
    scrape_html_listing(page_url: page_url, link_pattern: link_pattern, base_url: base_url, limit: limit)
  end

  def scrape_html_listing(page_url:, link_pattern:, base_url: nil, limit: 30)
    doc = Nokogiri::HTML(fetch_body(page_url))
    origin = base_url || @source.base_url

    doc.css("a[href]").filter_map do |link|
      href = link["href"].to_s.strip
      next if href.blank?
      next unless href.match?(link_pattern)

      url = href.start_with?("http") ? href : URI.join(origin, href).to_s
      title = link.at_css("h2, h3")&.text&.strip.presence ||
              link["title"].to_s.strip.presence ||
              link.text.to_s.squish
      next if title.blank? || title.length < 15

      {
        title: title,
        url: url,
        published_at: Time.current,
        content_snippet: title
      }
    end.uniq { |item| item[:url] }.first(limit)
  end
end
