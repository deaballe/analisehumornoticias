# Painel Humor do Ecossistema RS — Implementation Plan (Rails)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a public Rails dashboard that collects Gaúcho news twice daily via Sidekiq, analyzes dual sentiment with DeepSeek, highlights critical topics in red, and shows Top 3 summaries plus 7-day trend charts.

**Architecture:** Rails monolith — scrapers + services + Sidekiq jobs write to PostgreSQL; ERB/Hotwire views render the public dashboard. `sidekiq-cron` triggers at 07:00 and 18:00 BRT.

**Tech Stack:** Ruby 3.3+, Rails 7.2+, Sidekiq, sidekiq-cron, Redis, PostgreSQL, feedjira, nokogiri, faraday, ruby-openai (DeepSeek), tailwindcss-rails, chartkick, rspec-rails.

**Spec:** `docs/superpowers/specs/2026-06-20-painel-humor-ecossistema-rs-design.md`

---

## File Structure

```
analisehumornoticias/
├── Procfile.dev                    # web + css + sidekiq
├── Procfile                        # deploy: web + worker
├── .env.example
├── Gemfile
├── config/
│   ├── routes.rb
│   ├── schedule.yml                # sidekiq-cron
│   ├── initializers/deepseek.rb
│   └── sidekiq.yml
├── db/
│   ├── migrate/
│   └── seeds.rb
├── app/
│   ├── models/
│   ├── services/
│   ├── scrapers/
│   ├── jobs/news_pipeline_job.rb
│   ├── controllers/
│   ├── views/
│   └── helpers/
└── spec/
    ├── services/
    ├── scrapers/
    └── requests/
```

---

## Keywords seed (definitive)

```ruby
# db/seeds.rb
KEYWORDS = [
  ["acordo de resultados", []],
  ["projetos estratégicos", []],
  ["plano plurianual", %w[ppa]],
  ["ppa rs", %w[ppa plano\ plurianual\ rs]],
  ["modernização administrativa", []],
  ["reforma administrativa", []],
  ["eficiência na gestão", %w[eficiência gestão\ eficiente]],
  ["governo digital", []],
  ["rs.gov.br", %w[portal\ rs\ gov]],
  ["inovação no setor público", []],
  ["funcionalismo público", []],
  ["servidores estaduais", []],
  ["concurso público rs", %w[concurso\ público concurso\ rs]],
  ["patrimônio do estado", []],
  ["parcerias público-privadas", %w[ppp parceria\ público-privada]],
  ["ppp rs", %w[ppp parcerias\ público-privadas]],
  ["concessões públicas", []],
  ["spgg", %w[secretaria\ de\ planejamento\ governança\ e\ gestão]]
].freeze
```

---

### Task 1: Rails app scaffold

**Files:**
- Create: Rails app root, `Gemfile`, `.env.example`, `Procfile`, `Procfile.dev`

- [ ] **Step 1: Generate Rails app**

Run:
```bash
rails new . --database=postgresql --css=tailwind --skip-test
```

- [ ] **Step 2: Add gems to `Gemfile`**

```ruby
gem "sidekiq"
gem "sidekiq-cron"
gem "redis"
gem "feedjira"
gem "nokogiri"
gem "faraday"
gem "ruby-openai"
gem "chartkick"
gem "groupdate"
gem "rack-attack"

group :development, :test do
  gem "rspec-rails"
  gem "webmock"
  gem "vcr"
  gem "dotenv-rails"
end
```

Run: `bundle install`

- [ ] **Step 3: Create `.env.example`**

```bash
DATABASE_URL=postgresql://humor:humor@localhost:5432/humor_rs_development
REDIS_URL=redis://localhost:6379/0
DEEPSEEK_API_KEY=
DEEPSEEK_BASE_URL=https://api.deepseek.com
DEEPSEEK_MODEL=deepseek-v4-flash
```

- [ ] **Step 4: Configure ActiveJob → Sidekiq**

```ruby
# config/application.rb
config.active_job.queue_adapter = :sidekiq
```

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "chore: scaffold Rails app with Sidekiq and dependencies"
```

---

### Task 2: Models and migrations

**Files:**
- Create: `db/migrate/*`, `app/models/*.rb`

- [ ] **Step 1: Generate models**

Run:
```bash
rails g model Source slug:string:uniq name:string base_url:text fetch_type:string fetch_config:jsonb
rails g model Keyword term:string:uniq synonyms:string
rails g model Article source:references title:text url:text:uniq published_at:datetime content_snippet:text
rails g model ArticleAnalysis article:references keyword:references sentiment_institutional:string sentiment_thematic:string relevance_score:integer
rails g model DailySnapshot snapshot_date:date slot:string keyword:references pct_positive:decimal pct_neutral:decimal pct_negative:decimal article_count:integer is_critical:boolean
rails g model DailyBriefing briefing_date:date slot:string items:jsonb
```

Add unique indexes per spec section 9.

- [ ] **Step 2: Add model validations and associations**

```ruby
# app/models/article_analysis.rb
validates :sentiment_institutional, inclusion: { in: %w[positive neutral negative] }
validates :sentiment_thematic, inclusion: { in: %w[positive neutral negative] }
```

- [ ] **Step 3: Run migrations**

Run: `rails db:create db:migrate`
Expected: 6 tables created

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: add ActiveRecord models and migrations"
```

---

### Task 3: Seed sources and keywords

**Files:**
- Modify: `db/seeds.rb`

- [ ] **Step 1: Write seeds for 7 sources + 18 keywords**

```ruby
sources = [
  { slug: "g1_rs", name: "G1 RS", fetch_type: "rss", fetch_config: { url: "..." } },
  { slug: "zero_hora", name: "Zero Hora", fetch_type: "rss", fetch_config: { url: "..." } },
  # ... correio, gaucha_zh, anp, sul21, agencia_brasil
]
sources.each { |attrs| Source.find_or_create_by!(slug: attrs[:slug]) { |s| s.assign_attributes(attrs) } }

KEYWORDS.each { |term, synonyms| Keyword.find_or_create_by!(term: term) { |k| k.synonyms = synonyms } }
```

- [ ] **Step 2: Run seed**

Run: `rails db:seed`
Expected: 7 sources, 18 keywords

- [ ] **Step 3: Commit**

```bash
git commit -m "feat: seed 7 news sources and 18 keywords"
```

---

### Task 4: KeywordMatcher service (TDD)

**Files:**
- Create: `app/services/keyword_matcher.rb`, `spec/services/keyword_matcher_spec.rb`

- [ ] **Step 1: Write failing spec**

```ruby
RSpec.describe KeywordMatcher do
  let(:keywords) { [Keyword.new(id: 1, term: "spgg", synonyms: ["secretaria de planejamento"])] }

  it "matches term in title" do
    article = Article.new(title: "SPGG apresenta novo plano", content_snippet: "")
    matches = described_class.call(article, keywords)
    expect(matches.map(&:id)).to eq([1])
  end

  it "matches synonym case-insensitively" do
    kw = Keyword.new(id: 2, term: "ppp rs", synonyms: ["parcerias público-privadas"])
    article = Article.new(title: "Estado avança em Parcerias Público-Privadas", content_snippet: "")
    expect(described_class.call(article, [kw]).map(&:id)).to eq([2])
  end
end
```

- [ ] **Step 2: Run — expect FAIL**

Run: `bundle exec rspec spec/services/keyword_matcher_spec.rb`
Expected: FAIL

- [ ] **Step 3: Implement `KeywordMatcher`**

```ruby
class KeywordMatcher
  def self.call(article, keywords)
    haystack = "#{article.title} #{article.content_snippet}".downcase
    keywords.select do |kw|
      terms = [kw.term, *kw.synonyms].map(&:downcase)
      terms.any? { |t| haystack.include?(t) }
    end
  end
end
```

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: keyword matcher with synonym support"
```

---

### Task 5: RelevanceScorer + SnapshotAggregator (TDD)

**Files:**
- Create: `app/services/relevance_scorer.rb`, `app/services/snapshot_aggregator.rb`, specs

- [ ] **Step 1: Write specs for relevance and critical logic**

Test: score >= 70 for recent dual-negative title match; `is_critical` true at >= 60% negative; high-impact trigger.

- [ ] **Step 2: Implement both services per spec sections 7–8**

- [ ] **Step 3: Run specs — expect PASS**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: relevance scoring and snapshot aggregation with critical detection"
```

---

### Task 6: RSS scraper base + G1 RS scraper

**Files:**
- Create: `app/scrapers/base_scraper.rb`, `app/scrapers/g1_rs_scraper.rb`, `spec/scrapers/g1_rs_scraper_spec.rb`

- [ ] **Step 1: Implement `BaseScraper`**

```ruby
class BaseScraper
  def self.call(source)
    new(source).fetch
  end

  def initialize(source)
    @source = source
  end

  private

  def http_client
    @http_client ||= Faraday.new do |f|
      f.headers["User-Agent"] = "HumorEcossistemaRS/1.0 (+https://github.com/deaballe/analisehumornoticias)"
      f.options.timeout = 15
    end
  end
end
```

- [ ] **Step 2: Implement `G1RsScraper` with Feedjira**

Returns array of `{ title:, url:, published_at:, content_snippet: }`.

- [ ] **Step 3: VCR spec with recorded RSS fixture**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: base scraper and G1 RS RSS collector"
```

---

### Task 7: Remaining scrapers (6 sources)

**Files:**
- Create: `app/scrapers/zero_hora_scraper.rb`, `correio_do_povo_scraper.rb`, etc.
- Create: `app/scrapers/registry.rb`

- [ ] **Step 1: One scraper per source**

- [ ] **Step 2: Registry maps `source.slug` → scraper class**

```ruby
module Scrapers
  REGISTRY = {
    "g1_rs" => G1RsScraper,
    "zero_hora" => ZeroHoraScraper,
    # ...
  }.freeze
end
```

- [ ] **Step 3: Smoke test — `NewsPipeline.new(slot: "manha").collect` returns articles**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: scrapers for all 7 news sources"
```

---

### Task 8: DeepSeek SentimentAnalyzer + BriefingGenerator

**Files:**
- Create: `config/initializers/deepseek.rb`, `app/services/sentiment_analyzer.rb`, `app/services/briefing_generator.rb`, specs

- [ ] **Step 1: DeepSeek initializer**

```ruby
# config/initializers/deepseek.rb
DEEPSEEK_CLIENT = OpenAI::Client.new(
  access_token: ENV.fetch("DEEPSEEK_API_KEY"),
  uri_base: ENV.fetch("DEEPSEEK_BASE_URL", "https://api.deepseek.com")
)
```

- [ ] **Step 2: Implement `SentimentAnalyzer`**

Returns `{ sentiment_institutional:, sentiment_thematic: }` via JSON response. Retry 2×; fallback `neutral`.

- [ ] **Step 3: Implement `BriefingGenerator`**

Top 3 by relevance; 2–3 sentence summary per article via DeepSeek.

- [ ] **Step 4: WebMock specs — no real API calls in CI**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: DeepSeek sentiment analysis and Top 3 briefing generator"
```

---

### Task 9: NewsPipeline + NewsPipelineJob

**Files:**
- Create: `app/services/news_pipeline.rb`, `app/jobs/news_pipeline_job.rb`

- [ ] **Step 1: Implement `NewsPipeline#run`**

Orchestrates: collect → dedupe → match → analyze → score → snapshot → briefing.

- [ ] **Step 2: Implement job**

```ruby
class NewsPipelineJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  def perform(slot)
    NewsPipeline.new(slot: slot).run
  end
end
```

- [ ] **Step 3: Manual run**

Run: `rails runner "NewsPipelineJob.perform_now('manha')"`
Expected: data in DB (requires DEEPSEEK_API_KEY)

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: news pipeline orchestrator and Sidekiq job"
```

---

### Task 10: sidekiq-cron schedule

**Files:**
- Create: `config/schedule.yml`, update `config/initializers/sidekiq.rb`

- [ ] **Step 1: Add schedule.yml per spec section 12**

- [ ] **Step 2: Load cron in Sidekiq initializer**

```ruby
Sidekiq::Cron::Job.load_from_hash YAML.load_file(Rails.root.join("config/schedule.yml"))
```

- [ ] **Step 3: Verify in Sidekiq Web UI (dev)**

Run sidekiq; confirm 2 cron entries visible

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: schedule pipeline at 07h and 18h BRT via sidekiq-cron"
```

---

### Task 11: Dashboard UI (home)

**Files:**
- Create: `app/controllers/dashboard_controller.rb`, `app/views/dashboard/index.html.erb`, partials

- [ ] **Step 1: Routes**

```ruby
root "dashboard#index"
resources :keywords, only: [:show]
```

- [ ] **Step 2: Controller loads latest briefing + snapshots + 7d history**

- [ ] **Step 3: Partials**

- `_top_briefing.html.erb` — Top 3 cards
- `_keyword_card.html.erb` — red border if `is_critical`
- `_trend_chart.html.erb` — Chartkick line chart

- [ ] **Step 4: Verify in browser**

Run: `bin/dev` → `http://localhost:3000`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: public dashboard home with Top 3, keyword cards, and 7-day chart"
```

---

### Task 12: Keyword detail page

**Files:**
- Create: `app/controllers/keywords_controller.rb`, `app/views/keywords/show.html.erb`

- [ ] **Step 1: Show articles for keyword in latest slot**

Highlight high-impact (`relevance_score >= 70`)

- [ ] **Step 2: Sentiment badges partial**

- [ ] **Step 3: Request spec**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: keyword detail page with article list and sentiment badges"
```

---

### Task 13: Deploy config (Render)

**Files:**
- Create: `render.yaml` or `Procfile`, update `README.md`

- [ ] **Step 1: Procfile**

```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
```

- [ ] **Step 2: Document env vars and Render setup in README**

- [ ] **Step 3: Commit**

```bash
git commit -m "docs: add deploy config for web + Sidekiq worker"
```

---

### Task 14: README + full verification

- [ ] **Step 1: Run full spec suite**

Run: `bundle exec rspec`
Expected: all pass

- [ ] **Step 2: Run pipeline locally end-to-end**

- [ ] **Step 3: Verify MVP checklist from spec section 15**

- [ ] **Step 4: Final commit**

```bash
git commit -m "docs: README and MVP verification"
```

---

## Spec Coverage Checklist

| Spec requirement | Task |
|------------------|------|
| Rails monolito | Task 1 |
| Sidekiq + sidekiq-cron 2×/dia | Task 9, 10 |
| 7 scrapers | Task 6, 7 |
| 18 keywords seed | Task 3 |
| DeepSeek dual sentiment | Task 8 |
| Top 3 briefing | Task 8, 9 |
| Critical visual (≥60% or high impact) | Task 5, 11 |
| 7-day chart (Chartkick) | Task 11 |
| Public routes, no auth | Task 11, 12 |
| Deploy web + worker | Task 13 |

---

**Plan complete.** Two execution options:

1. **Subagent-Driven (recommended)** — fresh subagent per task
2. **Inline Execution** — task-by-task in this session

Which approach?
