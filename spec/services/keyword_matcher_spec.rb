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
end
