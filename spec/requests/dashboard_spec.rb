require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "renders the home page" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Barômetro Gaúcho")
    expect(response.body).to include("Pressão da notícia sobre o ecossistema de gestão pública da SPGG/RS.")
  end

  it "lists monitored keywords even without a briefing" do
    create_test_keyword(term: "tema monitorado teste", section: "temas")
    create_test_keyword(term: "danielle calazans teste", section: "spgg_equipe")

    get root_path

    expect(response.body).to include("Temas monitorados")
    expect(response.body).to include("Cor: baseada no humor")
    expect(response.body).to include("Ponto de atenção")
    expect(response.body).to include("SPGG — secretária, adjunto e subsecretarias")
    expect(response.body).to include("Tema Monitorado Teste")
    expect(response.body).to include("Danielle Calazans Teste")
    expect(response.body).to include("Nenhuma matéria encontrada para este tema no ciclo atual.")
    expect(response.body).to include("O que é análise de humor, relevância e atenção")
    expect(response.body).to include("Cálculo de humor")
    expect(response.body).to include("Cálculo de relevância")
    expect(response.body).to include("Institucional")
    expect(response.body).to include("Temático")
    expect(response.body).to include("Magnitude negativa")
    expect(response.body).to include("Fontes e atualização")
    expect(response.body).to include("Cálculo de atenção")
    expect(response.body).to include("problema institucional")
  end

  it "renders Top 3 for legacy briefing items without attention_score" do
    source = create_test_source
    keyword = create_test_keyword(term: "legado top3 teste")
    article = Article.create!(
      source: source,
      title: "Matéria legada sem attention_score",
      url: "https://example.com/legado-#{SecureRandom.hex(4)}",
      published_at: 1.hour.ago,
      content_snippet: "contexto legado"
    )
    analysis = ArticleAnalysis.create!(
      article: article,
      keyword: keyword,
      sentiment_institutional: "negative",
      sentiment_thematic: "neutral",
      relevance_score: 80
    )

    DailyBriefing.create!(
      briefing_date: Time.zone.today,
      slot: "manha",
      items: [
        {
          "article_id" => article.id,
          "title" => article.title,
          "url" => article.url,
          "source" => source.name,
          "relevance_score" => analysis.relevance_score,
          "summary" => "Resumo legado sem attention_score"
        }
      ]
    )

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Matéria legada sem attention_score")
    expect(response.body).to include("Atenção")
  end
end

RSpec.describe "Keywords", type: :request do
  it "renders keyword detail page" do
    keyword = create_test_keyword(term: "keyword detalhe teste")
    get keyword_path(keyword)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("keyword detalhe teste")
  end

  it "lists matched articles ordered by date with sentiment badges" do
    keyword = create_test_keyword(term: "keyword ciclo teste")
    source = create_test_source
    DailyBriefing.find_or_create_by!(briefing_date: Time.zone.today, slot: "manha") do |record|
      record.items = []
    end

    older = Article.create!(
      source: source,
      title: "Matéria mais antiga",
      url: "https://example.com/antiga-#{SecureRandom.hex(4)}",
      published_at: 3.days.ago,
      content_snippet: "contexto antigo"
    )
    newer = Article.create!(
      source: source,
      title: "Matéria mais recente",
      url: "https://example.com/recente-#{SecureRandom.hex(4)}",
      published_at: 1.hour.ago,
      content_snippet: "contexto recente"
    )

    [ older, newer ].each do |article|
      ArticleAnalysis.create!(
        article: article,
        keyword: keyword,
        sentiment_institutional: "neutral",
        sentiment_thematic: "negative",
        relevance_score: 80
      )
    end

    get keyword_path(keyword)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Matéria mais recente")
    expect(response.body).to include("Matéria mais antiga")
    expect(response.body.index("Matéria mais recente")).to be < response.body.index("Matéria mais antiga")
    expect(response.body).to include("Mediana do humor")
    expect(response.body).to include("O que é análise de humor, relevância e atenção")
    expect(response.body).to match(/Humor \d+\/100/)
    expect(response.body).to include("Relevância 80")
    expect(response.body).to include("ranqueia destaque no painel")
  end
end
