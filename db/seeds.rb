require Rails.root.join("lib/seed_keywords")

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
    fetch_config: { url: "https://gauchazh.clicrbs.com.br/politica/ultimas-noticias/" }
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
    slug: "jornal_do_comercio",
    name: "Jornal do Comércio",
    base_url: "https://www.jornaldocomercio.com/",
    fetch_type: "rss",
    fetch_config: {
      urls: [
        "https://www.jornaldocomercio.com/_conteudo/politica/rss.xml",
        "https://www.jornaldocomercio.com/_conteudo/economia/rss.xml"
      ]
    }
  },
  {
    slug: "radio_guaiba",
    name: "Rádio Guaíba",
    base_url: "https://guaiba.com.br/",
    fetch_type: "rss",
    fetch_config: { url: "https://guaiba.com.br/feed/" }
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

if (anp = Source.find_by(slug: "anp")) && anp.articles.none?
  anp.destroy
end

SeedKeywords.each_with_section do |term, synonyms, section|
  keyword = Keyword.find_or_initialize_by(term: term)
  keyword.synonyms = synonyms
  keyword.section = section
  keyword.save!
end

keep_terms = SeedKeywords::LIST.map(&:first)
Keyword.where.not(term: keep_terms).find_each do |keyword|
  keyword.article_analyses.delete_all
  keyword.daily_snapshots.delete_all
  keyword.destroy!
end

puts "Seeded #{Source.count} sources and #{Keyword.count} keywords " \
     "(temas=#{Keyword.temas.count}, spgg_equipe=#{Keyword.spgg_equipe.count})"
