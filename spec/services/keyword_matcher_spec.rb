require "rails_helper"

RSpec.describe KeywordMatcher do
  let(:keywords) { [ Keyword.new(id: 1, term: "spgg", synonyms: [ "secretaria de planejamento" ]) ] }

  it "matches term in title" do
    article = Article.new(title: "SPGG apresenta novo plano", content_snippet: "")
    matches = described_class.call(article, keywords)
    expect(matches.map(&:id)).to eq([ 1 ])
  end

  it "matches synonym case-insensitively" do
    kw = Keyword.new(id: 2, term: "ppp rs", synonyms: [ "parcerias público-privadas" ])
    article = Article.new(title: "Estado avança em Parcerias Público-Privadas", content_snippet: "")
    expect(described_class.call(article, [ kw ]).map(&:id)).to eq([ 2 ])
  end

  it "matches multi-word terms when all words appear" do
    kw = Keyword.new(id: 3, term: "eficiência na gestão", synonyms: [])
    article = Article.new(title: "Medida melhora eficiência da gestão pública", content_snippet: "")
    expect(described_class.call(article, [ kw ]).map(&:id)).to eq([ 3 ])
  end

  it "ignores accents when matching" do
    kw = Keyword.new(id: 4, term: "modernização administrativa", synonyms: [])
    article = Article.new(title: "Estado anuncia modernizacao administrativa", content_snippet: "")
    expect(described_class.call(article, [ kw ]).map(&:id)).to eq([ 4 ])
  end

  it "does not match multi-word term via unrelated substring coincidence" do
    kw = Keyword.new(id: 5, term: "servidores estaduais", synonyms: [ "servidor estadual" ])
    article = Article.new(
      title: "Polícia Penal descobre plano de fuga no Presídio Feminino",
      content_snippet: "Servidores da Polícia Penal impediram fuga do Presídio Estadual Feminino."
    )
    expect(described_class.call(article, [ kw ])).to be_empty
  end

  it "matches plural forms of a single-word synonym" do
    kw = Keyword.new(id: 6, term: "servidores estaduais", synonyms: [ "servidor" ])
    article = Article.new(title: "Servidores protestam em Porto Alegre", content_snippet: "")
    expect(described_class.call(article, [ kw ]).map(&:id)).to eq([ 6 ])
  end

  it "matches domain headlines from the seed vocabulary" do
    keywords = [
      Keyword.new(id: 10, term: "concurso público rs", synonyms: [ "concurso público", "concurso estadual" ]),
      Keyword.new(id: 11, term: "governo digital", synonyms: [ "transformação digital", "digitalização" ]),
      Keyword.new(id: 12, term: "concessões públicas", synonyms: [ "concessão pública", "concessão" ]),
      Keyword.new(id: 13, term: "spgg", synonyms: [ "palácio piratini", "secretaria de planejamento" ])
    ]
    headlines = [
      "Abertas as inscrições para concurso público estadual",
      "Estado avança em transformação digital dos serviços",
      "Nova concessão de rodovia é assinada pelo governo",
      "Palácio Piratini anuncia pacote de gestão"
    ]

    matched = headlines.filter_map do |title|
      hits = described_class.call(Article.new(title: title, content_snippet: ""), keywords)
      hits.map(&:term) if hits.any?
    end

    expect(matched.size).to eq(4)
  end
end
