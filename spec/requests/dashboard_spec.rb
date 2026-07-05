require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "renders the home page" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Humor do Ecossistema RS")
  end

  it "lists monitored keywords even without a briefing" do
    keyword = create_test_keyword(term: "tema monitorado teste")

    get root_path

    expect(response.body).to include("tema monitorado teste")
    expect(response.body).to include("Sem cobertura neste ciclo")
  end
end

RSpec.describe "Keywords", type: :request do
  it "renders keyword detail page" do
    keyword = create_test_keyword(term: "keyword detalhe teste")
    get keyword_path(keyword)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("keyword detalhe teste")
  end

  it "shows analyses updated in the current cycle even when the article is older" do
    keyword = create_test_keyword(term: "keyword ciclo teste")
    source = create_test_source
    briefing = DailyBriefing.find_or_create_by!(briefing_date: Time.zone.today, slot: "manha") do |record|
      record.items = []
    end
    article = Article.create!(
      source: source,
      title: "Matéria antiga reanalisada",
      url: "https://example.com/antiga-#{SecureRandom.hex(4)}",
      published_at: 3.days.ago,
      content_snippet: "contexto",
      created_at: 3.days.ago
    )
    ArticleAnalysis.create!(
      article: article,
      keyword: keyword,
      sentiment_institutional: "neutral",
      sentiment_thematic: "negative",
      relevance_score: 80,
      updated_at: briefing.briefing_date.beginning_of_day + 8.hours
    )

    get keyword_path(keyword)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Matéria antiga reanalisada")
  end
end
