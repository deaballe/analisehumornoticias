class ScraperRegistry
  REGISTRY = {
    "g1_rs" => G1RsScraper,
    "zero_hora" => ZeroHoraScraper,
    "correio_do_povo" => CorreioDoPovoScraper,
    "gaucha_zh" => GauchaZhScraper,
    "anp" => AnpScraper,
    "sul21" => Sul21Scraper,
    "agencia_brasil" => AgenciaBrasilScraper
  }.freeze

  def self.for(source)
    REGISTRY.fetch(source.slug) { raise "No scraper registered for #{source.slug}" }
  end
end
