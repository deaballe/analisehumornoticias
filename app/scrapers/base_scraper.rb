class BaseScraper
  USER_AGENT = "HumorEcossistemaRS/1.0 (+https://github.com/deaballe/analisehumornoticias)".freeze
  REQUEST_DELAY = 2

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

  def fetch_body(url)
    sleep REQUEST_DELAY unless Rails.env.test?
    response = http_client.get(url)
    raise "HTTP #{response.status} for #{url}" unless response.success?

    response.body
  end

  def parse_rss(url)
    body = fetch_body(url)
    feed = Feedjira.parse(body)

    feed.entries.map do |entry|
      {
        title: entry.title.to_s.strip,
        url: entry.url.to_s.strip,
        published_at: entry.published || entry.updated,
        content_snippet: entry.summary.to_s.strip.truncate(500)
      }
    end.reject { |item| item[:title].blank? || item[:url].blank? }
  end
end
