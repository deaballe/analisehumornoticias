KEYWORDS = [
  [ "acordo de resultados", [] ],
  [ "projetos estratégicos", [] ],
  [ "plano plurianual", %w[ppa] ],
  [ "ppa rs", %w[ppa plano\ plurianual\ rs] ],
  [ "modernização administrativa", [] ],
  [ "reforma administrativa", [] ],
  [ "eficiência na gestão", %w[eficiência gestão\ eficiente] ],
  [ "governo digital", [] ],
  [ "rs.gov.br", %w[portal\ rs\ gov] ],
  [ "inovação no setor público", [] ],
  [ "funcionalismo público", [] ],
  [ "servidores estaduais", [] ],
  [ "concurso público rs", %w[concurso\ público concurso\ rs] ],
  [ "patrimônio do estado", [] ],
  [ "parcerias público-privadas", %w[ppp parceria\ público-privada] ],
  [ "ppp rs", %w[ppp parcerias\ público-privadas] ],
  [ "concessões públicas", [] ],
  [ "spgg", %w[secretaria\ de\ planejamento\ governança\ e\ gestão] ]
].freeze

sources = [
  {
    slug: "g1_rs",
    name: "G1 RS",
    base_url: "https://g1.globo.com/rs/",
    fetch_type: "rss",
    fetch_config: { url: "https://g1.globo.com/rss/g1/rs/" }
  },
  {
    slug: "zero_hora",
    name: "Zero Hora",
    base_url: "https://gauchazh.clicrbs.com.br/",
    fetch_type: "scrape",
    fetch_config: { url: "https://gauchazh.clicrbs.com.br/porto-alegre/ultimas-noticias/" }
  },
  {
    slug: "correio_do_povo",
    name: "Correio do Povo",
    base_url: "https://www.correiodopovo.com.br/",
    fetch_type: "scrape",
    fetch_config: { url: "https://www.correiodopovo.com.br/not%C3%ADcias/pol%C3%ADtica" }
  },
  {
    slug: "gaucha_zh",
    name: "Gaúcha ZH",
    base_url: "https://gauchazh.clicrbs.com.br/",
    fetch_type: "scrape",
    fetch_config: { url: "https://gauchazh.clicrbs.com.br/politica/ultimas-noticias/" }
  },
  {
    slug: "anp",
    name: "ANP",
    base_url: "https://anp.com.br/",
    fetch_type: "rss",
    fetch_config: { url: "https://anp.com.br/feed/" }
  },
  {
    slug: "sul21",
    name: "Sul21",
    base_url: "https://sul21.com.br/",
    fetch_type: "rss",
    fetch_config: { url: "https://sul21.com.br/feed/" }
  },
  {
    slug: "agencia_brasil",
    name: "Agência Brasil",
    base_url: "https://agenciabrasil.ebc.com.br/",
    fetch_type: "rss",
    fetch_config: { url: "https://agenciabrasil.ebc.com.br/rss/ultimasnoticias/feed.xml" }
  }
]

sources.each do |attrs|
  source = Source.find_or_initialize_by(slug: attrs[:slug])
  source.assign_attributes(attrs)
  source.save!
end

KEYWORDS.each do |term, synonyms|
  Keyword.find_or_create_by!(term: term) do |keyword|
    keyword.synonyms = synonyms
  end
end

puts "Seeded #{Source.count} sources and #{Keyword.count} keywords"
