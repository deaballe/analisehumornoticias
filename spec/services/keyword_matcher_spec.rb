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
end
