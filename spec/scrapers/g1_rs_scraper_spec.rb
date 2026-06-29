require "rails_helper"

RSpec.describe G1RsScraper do
  let(:source) do
    Source.new(
      slug: "g1_rs",
      name: "G1 RS",
      base_url: "https://g1.globo.com/rs/",
      fetch_type: "rss",
      fetch_config: { url: "https://g1.globo.com/rss/g1/rs/" }
    )
  end

  it "parses rss entries" do
    rss = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <title>SPGG apresenta plano</title>
            <link>https://g1.globo.com/rs/noticia</link>
            <description>Resumo da matéria</description>
            <pubDate>Sat, 28 Jun 2026 10:00:00 GMT</pubDate>
          </item>
        </channel>
      </rss>
    XML

    stub_request(:get, source.fetch_config["url"]).to_return(status: 200, body: rss)

    results = described_class.call(source)
    expect(results.length).to eq(1)
    expect(results.first[:title]).to include("SPGG")
  end
end
