require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "renders the home page" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Humor do Ecossistema RS")
  end
end

RSpec.describe "Keywords", type: :request do
  it "renders keyword detail page" do
    keyword = create_test_keyword(term: "keyword detalhe teste")
    get keyword_path(keyword)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("keyword detalhe teste")
  end
end
