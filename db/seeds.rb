KEYWORDS = [
  [ "acordo de resultados", %w[acordos\ de\ resultados acordo\ de\ resultados\ rs] ],
  [ "projetos estratégicos", %w[projeto\ estratégico projetos\ estrategicos] ],
  [ "plano plurianual", %w[ppa plano\ plurianual orçamento\ plurianual] ],
  [ "ppa rs", %w[ppa plano\ plurianual\ rs orçamento\ do\ estado fundo\ constitucional] ],
  [ "modernização administrativa", %w[modernização\ do\ estado modernizacao\ administrativa transformação\ administrativa] ],
  [ "reforma administrativa", %w[reforma\ do\ estado reforma\ do\ funcionalismo reestruturação\ administrativa] ],
  [ "eficiência na gestão", %w[eficiência gestão\ eficiente eficiencia\ na\ gestao gestão\ pública] ],
  [ "governo digital", %w[gov.br transformação\ digital governo\ eletrônico governo\ eletronico digitalização] ],
  [ "rs.gov.br", %w[portal\ rs\ gov estado.rs.gov.br estado.rs.gov] ],
  [ "inovação no setor público", %w[inovação\ pública inovacao\ no\ setor\ publico] ],
  [ "funcionalismo público", %w[funcionalismo servidor\ público servidores\ públicos rpps previdência\ própria] ],
  [ "servidores estaduais", %w[servidor\ estadual servidores\ do\ estado funcionário\ público\ estadual servidores] ],
  [ "concurso público rs", %w[concurso\ público concurso\ rs concurso\ público\ rs concurso\ estadual] ],
  [ "patrimônio do estado", %w[patrimônio\ público patrimonio\ do\ estado bens\ públicos] ],
  [ "parcerias público-privadas", %w[ppp parceria\ público-privada parcerias\ publico-privadas] ],
  [ "ppp rs", %w[ppp parcerias\ público-privadas parceria\ público-privada\ rs] ],
  [ "concessões públicas", %w[concessão\ pública concessoes\ publicas privatização] ],
  [ "spgg", %w[secretaria\ de\ planejamento\ governança\ e\ gestão secretaria\ de\ planejamento planejamento\ governança\ e\ gestão] ]
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
    fetch_config: { url: "https://gauchazh.clicrbs.com.br/pioneiro/politica/ultimas-noticias/" }
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

KEYWORDS.each do |term, synonyms|
  keyword = Keyword.find_or_initialize_by(term: term)
  keyword.synonyms = synonyms
  keyword.save!
end

puts "Seeded #{Source.count} sources and #{Keyword.count} keywords"
