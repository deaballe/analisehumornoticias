require "rails_helper"

RSpec.describe "Seed keyword coverage" do
  FIXTURES = [
    [ "Danielle Calazans anuncia pacote da SPGG", %w[danielle\ calazans spgg] ],
    [ "Felipe Cruzeiro representa a SPGG em reunião no Piratini", %w[felipe\ cruzeiro spgg] ],
    [ "SUPLAN: Carolina Scarparo detalha planejamento estadual", %w[suplan] ],
    [ "SUAD sob Liége Dresch publica novo ato administrativo", %w[suad] ],
    [ "SUGEP e Paula Caffarate anunciam concurso interno", %w[sugep] ],
    [ "SPE avalia patrimônio do Estado com Vinícius Deprá", %w[spe] ],
    [ "CELIC abre licitação sob Paulo Lunardi", %w[celic] ],
    [ "Carramilo apresenta estratégia de TIC da STI SPGG", %w[sti\ spgg] ],
    [ "Palácio Piratini confirma reunião sobre reconstrução do RS", %w[palácio\ piratini reconstrução\ do\ rs] ],
    [ "Funrigs libera recursos para municípios atingidos", %w[funrigs] ],
    [ "Enchentes no RS ativam Defesa Civil em alerta", %w[enchentes defesa\ civil] ],
    [ "Governo inicia entrega de casas em Canoas", %w[entrega\ de\ casas] ],
    [ "Programa de habitação amplia Minha Casa Minha Vida no Estado", %w[habitação] ],
    [ "Brigada Militar prende suspeitos após onda de criminalidade", %w[brigada\ militar criminalidade] ],
    [ "Polícia Civil investiga homicídio e tráfico de drogas", %w[polícia\ civil homicídios tráfico\ de\ drogas] ],
    [ "Estado busca eficiência na gestão e serviços digitais", %w[eficiência\ na\ gestão governo\ digital] ],
    [ "Assembleia Legislativa vota plano plurianual", %w[assembleia\ legislativa plano\ plurianual] ],
    [ "Nova PPP e concurso público estadual são anunciados", %w[parcerias\ público-privadas concurso\ público\ rs] ],
    [ "Servidores estaduais negociam reajuste no Palácio Piratini", %w[servidores\ estaduais palácio\ piratini] ]
  ].freeze

  def keywords_from_seeds
    keywords = []
    SeedKeywords.each_with_section do |term, synonyms, section|
      keywords << Keyword.new(id: keywords.size + 1, term: term, synonyms: synonyms, section: section)
    end
    keywords
  end

  it "matches curated headlines to the reorganized seed vocabulary" do
    keywords = keywords_from_seeds
    misses = []

    FIXTURES.each do |title, expected_terms|
      hits = KeywordMatcher.call(Article.new(title: title, content_snippet: ""), keywords).map(&:term)
      expected_terms.each do |term|
        misses << "#{title.inspect} missing #{term.inspect} (got #{hits.inspect})" unless hits.include?(term)
      end
    end

    expect(misses).to eq([])
  end

  it "does not treat bare 'casa' crime stories as entrega de casas" do
    keywords = keywords_from_seeds
    article = Article.new(
      title: "Idosos são encontrados mortos dentro de casa no interior do RS",
      content_snippet: ""
    )
    hits = KeywordMatcher.call(article, keywords).map(&:term)
    expect(hits).not_to include("entrega de casas", "habitação")
  end

  it "does not tag prison staffing stories as servidores estaduais" do
    keywords = keywords_from_seeds
    article = Article.new(
      title: "Polícia Penal descobre plano de fuga no Presídio Feminino",
      content_snippet: "Servidores da Polícia Penal impediram fuga do Presídio Estadual Feminino."
    )
    hits = KeywordMatcher.call(article, keywords).map(&:term)
    expect(hits).not_to include("servidores estaduais")
  end
end
