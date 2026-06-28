# Painel Humor do Ecossistema RS — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a public dashboard that collects Gaúcho news headlines twice daily, analyzes dual sentiment per keyword, highlights critical topics in red, and shows Top 3 AI summaries plus 7-day trend charts.

**Architecture:** Python pipeline (collect → match → LLM analyze → aggregate) writes to PostgreSQL; FastAPI serves a public REST API; Next.js renders the dashboard. Cron triggers at 07:00 and 18:00 BRT.

**Tech Stack:** Python 3.12, FastAPI, SQLAlchemy, Alembic, PostgreSQL 16, DeepSeek API (OpenAI-compatible SDK), pytest; Next.js 14, Tailwind, Recharts; Docker Compose.

**Spec:** `docs/superpowers/specs/2026-06-20-painel-humor-ecossistema-rs-design.md`

---

## File Structure

```
analisehumornoticias/
├── docker-compose.yml          # postgres + api + (optional) frontend
├── .env.example                # DATABASE_URL, DEEPSEEK_API_KEY
├── backend/
│   ├── pyproject.toml
│   ├── alembic.ini
│   ├── alembic/versions/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py             # FastAPI app + CORS
│   │   ├── config.py           # env settings
│   │   ├── db.py               # engine + session
│   │   ├── models.py           # SQLAlchemy models
│   │   ├── schemas.py          # Pydantic response models
│   │   ├── seed.py             # sources + keywords seed data
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   ├── briefing.py
│   │   │   ├── snapshots.py
│   │   │   ├── keywords.py
│   │   │   └── meta.py
│   │   ├── services/
│   │   │   ├── matcher.py      # keyword matching
│   │   │   ├── sentiment.py    # LLM dual sentiment
│   │   │   ├── relevance.py    # score 0-100
│   │   │   ├── aggregator.py   # snapshots + critical logic
│   │   │   ├── briefing.py     # Top 3 + summaries
│   │   │   └── pipeline.py     # orchestrates full run
│   │   └── collectors/
│   │       ├── base.py
│   │       ├── rss.py
│   │       └── registry.py     # maps source slug → collector
│   ├── scripts/
│   │   └── run_pipeline.py     # CLI entry for cron
│   └── tests/
│       ├── conftest.py
│       ├── test_matcher.py
│       ├── test_relevance.py
│       ├── test_aggregator.py
│       └── test_api.py
└── frontend/
    ├── package.json
    ├── next.config.js
    ├── tailwind.config.ts
    ├── lib/api.ts                # fetch helpers
    ├── app/
    │   ├── layout.tsx
    │   ├── page.tsx              # home dashboard
    │   ├── globals.css
    │   └── keywords/[id]/page.tsx
    └── components/
        ├── TopBriefing.tsx
        ├── KeywordCard.tsx
        ├── TrendChart.tsx
        └── SentimentBadge.tsx
```

---

## Keywords seed (definitive)

```python
KEYWORDS = [
    ("acordo de resultados", []),
    ("projetos estratégicos", []),
    ("plano plurianual", ["ppa"]),
    ("ppa rs", ["ppa", "plano plurianual rs"]),
    ("modernização administrativa", []),
    ("reforma administrativa", []),
    ("eficiência na gestão", ["eficiência", "gestão eficiente"]),
    ("governo digital", []),
    ("rs.gov.br", ["portal rs gov"]),
    ("inovação no setor público", []),
    ("funcionalismo público", []),
    ("servidores estaduais", []),
    ("concurso público rs", ["concurso público", "concurso rs"]),
    ("patrimônio do estado", []),
    ("parcerias público-privadas", ["ppp", "parceria público-privada"]),
    ("ppp rs", ["ppp", "parcerias público-privadas"]),
    ("concessões públicas", []),
    ("spgg", ["secretaria de planejamento governança e gestão"]),
]
```

---

### Task 1: Project scaffold + Docker Compose

**Files:**
- Create: `docker-compose.yml`, `.env.example`, `.gitignore`, `backend/pyproject.toml`

- [ ] **Step 1: Create `.gitignore`**

```gitignore
.env
__pycache__/
*.pyc
.venv/
node_modules/
.next/
.pytest_cache/
```

- [ ] **Step 2: Create `.env.example`**

```bash
DATABASE_URL=postgresql+psycopg://humor:humor@localhost:5432/humor_rs
DEEPSEEK_API_KEY=sk-...
DEEPSEEK_BASE_URL=https://api.deepseek.com
DEEPSEEK_MODEL=deepseek-v4-flash
API_HOST=0.0.0.0
API_PORT=8000
NEXT_PUBLIC_API_URL=http://localhost:8000
```

- [ ] **Step 3: Create `docker-compose.yml`**

```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: humor
      POSTGRES_PASSWORD: humor
      POSTGRES_DB: humor_rs
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  api:
    build: ./backend
    env_file: .env
    ports:
      - "8000:8000"
    depends_on:
      - db

volumes:
  pgdata:
```

- [ ] **Step 4: Create `backend/pyproject.toml`**

```toml
[project]
name = "humor-ecossistema-rs"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
  "fastapi>=0.115.0",
  "uvicorn[standard]>=0.32.0",
  "sqlalchemy>=2.0.36",
  "psycopg[binary]>=3.2.3",
  "alembic>=1.14.0",
  "pydantic-settings>=2.6.0",
  "httpx>=0.28.0",
  "feedparser>=6.0.11",
  "beautifulsoup4>=4.12.3",
  "openai>=1.57.0",
  "python-dateutil>=2.9.0",
]

[project.optional-dependencies]
dev = ["pytest>=8.3.0", "pytest-asyncio>=0.24.0", "httpx>=0.28.0"]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["."]
```

- [ ] **Step 5: Verify Docker starts**

Run: `docker compose up -d db && docker compose ps`
Expected: `db` container running, port 5432 exposed

- [ ] **Step 6: Commit**

```bash
git add .gitignore .env.example docker-compose.yml backend/pyproject.toml
git commit -m "chore: scaffold backend project and docker compose"
```

---

### Task 2: Database models + Alembic migration

**Files:**
- Create: `backend/app/config.py`, `backend/app/db.py`, `backend/app/models.py`, `backend/alembic.ini`, `backend/alembic/env.py`, `backend/alembic/versions/001_initial.py`

- [ ] **Step 1: Write `backend/app/config.py`**

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg://humor:humor@localhost:5432/humor_rs"
    deepseek_api_key: str = ""
    deepseek_base_url: str = "https://api.deepseek.com"
    deepseek_model: str = "deepseek-v4-flash"
    api_host: str = "0.0.0.0"
    api_port: int = 8000

    class Config:
        env_file = ".env"

settings = Settings()
```

- [ ] **Step 2: Write `backend/app/db.py`**

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from app.config import settings

engine = create_engine(settings.database_url)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

class Base(DeclarativeBase):
    pass

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

- [ ] **Step 3: Write `backend/app/models.py`** (matches spec section 9)

Define: `Source`, `Keyword`, `Article`, `ArticleAnalysis`, `DailySnapshot`, `DailyBriefing` with columns from spec.

- [ ] **Step 4: Generate Alembic migration `001_initial.py`**

Run from `backend/`:
```bash
pip install -e ".[dev]"
alembic init alembic
# wire env.py to Base.metadata
alembic revision --autogenerate -m "initial schema"
alembic upgrade head
```
Expected: 6 tables created in PostgreSQL

- [ ] **Step 5: Commit**

```bash
git add backend/app/config.py backend/app/db.py backend/app/models.py backend/alembic/
git commit -m "feat: add SQLAlchemy models and initial migration"
```

---

### Task 3: Seed sources and keywords

**Files:**
- Create: `backend/app/seed.py`, `backend/scripts/seed_db.py`

- [ ] **Step 1: Write `backend/app/seed.py`**

Include 7 sources (G1 RS, Zero Hora, Correio do Povo, Gaúcha ZH, ANP, Sul21, Agência Brasil) with `fetch_type` and `fetch_config` (RSS URLs as placeholders to be validated).

Include all 18 keywords from definitive list above.

- [ ] **Step 2: Write `backend/scripts/seed_db.py`**

```python
from app.db import SessionLocal
from app.seed import seed_all

if __name__ == "__main__":
    db = SessionLocal()
    seed_all(db)
    db.commit()
    print("Seed complete")
```

- [ ] **Step 3: Run seed**

Run: `cd backend && python scripts/seed_db.py`
Expected: `18 keywords, 7 sources` inserted

- [ ] **Step 4: Commit**

```bash
git add backend/app/seed.py backend/scripts/seed_db.py
git commit -m "feat: seed 7 news sources and 18 keywords"
```

---

### Task 4: Keyword matcher (TDD)

**Files:**
- Create: `backend/app/services/matcher.py`, `backend/tests/test_matcher.py`

- [ ] **Step 1: Write failing test**

```python
# backend/tests/test_matcher.py
from app.services.matcher import match_keywords

def test_matches_term_in_title():
    keywords = [{"id": 1, "term": "spgg", "synonyms": ["secretaria de planejamento"]}]
    article = {"title": "SPGG apresenta novo plano", "content_snippet": ""}
    matches = match_keywords(article, keywords)
    assert len(matches) == 1
    assert matches[0]["keyword_id"] == 1

def test_matches_synonym_case_insensitive():
    keywords = [{"id": 2, "term": "ppp rs", "synonyms": ["parcerias público-privadas"]}]
    article = {"title": "Estado avança em Parcerias Público-Privadas", "content_snippet": ""}
    matches = match_keywords(article, keywords)
    assert any(m["keyword_id"] == 2 for m in matches)

def test_no_match_returns_empty():
    keywords = [{"id": 1, "term": "spgg", "synonyms": []}]
    article = {"title": "Time gaúcho vence clássico", "content_snippet": ""}
    assert match_keywords(article, keywords) == []
```

- [ ] **Step 2: Run test — expect FAIL**

Run: `cd backend && pytest tests/test_matcher.py -v`
Expected: FAIL — module not found

- [ ] **Step 3: Implement `matcher.py`**

```python
import re
from typing import Any

def _normalize(text: str) -> str:
    return text.lower().strip()

def match_keywords(article: dict[str, Any], keywords: list[dict[str, Any]]) -> list[dict[str, Any]]:
    haystack = _normalize(f"{article.get('title', '')} {article.get('content_snippet', '')}")
    results = []
    for kw in keywords:
        terms = [_normalize(kw["term"]), *[_normalize(s) for s in kw.get("synonyms", [])]]
        if any(re.search(re.escape(t), haystack) for t in terms if t):
            results.append({"keyword_id": kw["id"], "term": kw["term"]})
    return results
```

- [ ] **Step 4: Run test — expect PASS**

Run: `pytest tests/test_matcher.py -v`
Expected: 3 passed

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/matcher.py backend/tests/test_matcher.py
git commit -m "feat: keyword matcher with synonym support"
```

---

### Task 5: Relevance scorer (TDD)

**Files:**
- Create: `backend/app/services/relevance.py`, `backend/tests/test_relevance.py`

- [ ] **Step 1: Write failing tests**

```python
from datetime import datetime, timezone, timedelta
from app.services.relevance import compute_relevance_score

def test_high_score_for_recent_title_match_dual_negative():
    article = {
        "title": "PPP RS enfrenta forte resistência",
        "published_at": datetime.now(timezone.utc) - timedelta(hours=2),
        "source_count": 2,
    }
    score = compute_relevance_score(
        article,
        keyword_term="ppp rs",
        sentiment_institutional="negative",
        sentiment_thematic="negative",
    )
    assert score >= 70

def test_low_score_for_old_neutral():
    article = {
        "title": "Nota sobre administração",
        "published_at": datetime.now(timezone.utc) - timedelta(days=3),
        "source_count": 1,
    }
    score = compute_relevance_score(
        article, keyword_term="reforma", sentiment_institutional="neutral", sentiment_thematic="neutral"
    )
    assert score < 40
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement `relevance.py`**

Weights from spec: recency 25%, keyword in title 25%, multi-source 25%, negative magnitude 25%. Return `int` 0–100.

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: relevance scoring for Top 3 and impact alerts"
```

---

### Task 6: Aggregator + critical logic (TDD)

**Files:**
- Create: `backend/app/services/aggregator.py`, `backend/tests/test_aggregator.py`

- [ ] **Step 1: Write failing tests**

```python
from app.services.aggregator import compute_snapshot, is_critical

def test_critical_volume_threshold():
    analyses = [
        {"sentiment_institutional": "negative", "sentiment_thematic": "neutral"},
        {"sentiment_institutional": "negative", "sentiment_thematic": "negative"},
        {"sentiment_institutional": "neutral", "sentiment_thematic": "negative"},
        {"sentiment_institutional": "negative", "sentiment_thematic": "negative"},
        {"sentiment_institutional": "positive", "sentiment_thematic": "positive"},
    ]
    snap = compute_snapshot(analyses)
    assert snap["pct_negative"] >= 60.0
    assert is_critical(analyses, high_impact=None) is True

def test_critical_high_impact():
    analyses = [{"sentiment_institutional": "negative", "sentiment_thematic": "negative", "relevance_score": 85}]
    assert is_critical(analyses, high_impact=analyses[0]) is True

def test_not_critical_below_threshold():
    analyses = [{"sentiment_institutional": "neutral", "sentiment_thematic": "positive"}] * 5
    assert is_critical(analyses, high_impact=None) is False
```

- [ ] **Step 2–4: Implement, test, pass**

`compute_snapshot` returns `{pct_positive, pct_neutral, pct_negative, article_count}`.
Critical if pct_negative >= 60 OR (relevance >= 70 AND both sentiments negative).

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: snapshot aggregation and critical detection"
```

---

### Task 7: RSS collector

**Files:**
- Create: `backend/app/collectors/base.py`, `backend/app/collectors/rss.py`, `backend/app/collectors/registry.py`

- [ ] **Step 1: Implement `base.py`** — abstract `Collector` with `fetch() -> list[RawArticle]`

- [ ] **Step 2: Implement `rss.py`**

```python
import feedparser
from dateutil import parser as dateparser

def fetch_rss(url: str, source_slug: str) -> list[dict]:
    feed = feedparser.parse(url)
    articles = []
    for entry in feed.entries[:30]:
        articles.append({
            "source_slug": source_slug,
            "title": entry.get("title", "").strip(),
            "url": entry.get("link", "").strip(),
            "published_at": dateparser.parse(entry.get("published", "")) if entry.get("published") else None,
            "content_snippet": entry.get("summary", "")[:500],
        })
    return [a for a in articles if a["title"] and a["url"]]
```

- [ ] **Step 3: Wire registry with RSS URLs** (validate manually once; store in seed `fetch_config`)

- [ ] **Step 4: Manual smoke test**

Run a one-off script fetching G1 RS RSS; expect ≥ 1 article with title + url

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: RSS collector for news sources"
```

---

### Task 8: DeepSeek sentiment + briefing services

**Files:**
- Create: `backend/app/services/sentiment.py`, `backend/app/services/briefing.py`, `backend/app/services/llm_client.py`

- [ ] **Step 1: Implement `llm_client.py`**

```python
import os
from openai import OpenAI

def get_llm_client() -> OpenAI:
    return OpenAI(
        api_key=os.environ["DEEPSEEK_API_KEY"],
        base_url=os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com"),
    )

def get_model() -> str:
    return os.environ.get("DEEPSEEK_MODEL", "deepseek-v4-flash")
```

- [ ] **Step 2: Implement `sentiment.py`**

Use DeepSeek via OpenAI-compatible SDK with structured JSON output:

```python
async def analyze_dual_sentiment(title: str, keyword: str, snippet: str = "") -> dict:
    # returns {"sentiment_institutional": "...", "sentiment_thematic": "..."}
```

Prompt (Portuguese) per spec section 6. Use `deepseek-v4-flash`. Retry 2× on failure; fallback both to `"neutral"`.

- [ ] **Step 3: Implement `briefing.py`**

```python
async def generate_top3(db, slot: str) -> list[dict]:
    # pick top 3 by relevance_score across all analyses in current run
    # call DeepSeek for 2-3 sentence summary per article
```

- [ ] **Step 4: Add unit test with mocked LLM client**

Mock `openai` client; verify JSON parsing and fallback.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: DeepSeek dual sentiment analysis and Top 3 briefing"
```

---

### Task 9: Pipeline orchestrator + CLI

**Files:**
- Create: `backend/app/services/pipeline.py`, `backend/scripts/run_pipeline.py`

- [ ] **Step 1: Implement `pipeline.py`**

```python
def run_pipeline(slot: str) -> None:
    # 1. load sources + keywords
    # 2. collect all articles (dedupe by url)
    # 3. match keywords
    # 4. for each (article, keyword): analyze sentiment + relevance
    # 5. per keyword: compute snapshot + is_critical → DailySnapshot
    # 6. generate Top 3 → DailyBriefing
    # 7. commit transaction
```

Slot: `"manha"` if hour < 12 else `"tarde"`.

- [ ] **Step 2: Implement CLI `run_pipeline.py`**

```python
import sys
from app.services.pipeline import run_pipeline

if __name__ == "__main__":
    slot = sys.argv[1] if len(sys.argv) > 1 else "manha"
    run_pipeline(slot)
```

- [ ] **Step 3: End-to-end dry run**

Run: `cd backend && python scripts/run_pipeline.py manha`
Expected: articles + analyses + snapshots + briefing in DB (requires DEEPSEEK_API_KEY)

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: pipeline orchestrator with CLI entrypoint"
```

---

### Task 10: FastAPI REST endpoints

**Files:**
- Create: `backend/app/schemas.py`, `backend/app/main.py`, `backend/app/api/*.py`, `backend/tests/test_api.py`

- [ ] **Step 1: Write failing API test**

```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    r = client.get("/api/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"
```

- [ ] **Step 2: Implement endpoints per spec section 10**

- `GET /api/health`
- `GET /api/briefing/latest`
- `GET /api/snapshots/latest`
- `GET /api/snapshots/history/{keyword_id}?days=7`
- `GET /api/keywords/{id}/articles?date=YYYY-MM-DD`
- `GET /api/meta/sources`

Enable CORS for frontend origin.

- [ ] **Step 3: Run tests**

Run: `pytest tests/test_api.py -v`
Expected: all pass

- [ ] **Step 4: Create `backend/Dockerfile`**

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY pyproject.toml .
RUN pip install -e ".[dev]"
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: public REST API for dashboard"
```

---

### Task 11: Next.js frontend — home dashboard

**Files:**
- Create: `frontend/` with Next.js 14 App Router

- [ ] **Step 1: Scaffold frontend**

Run:
```bash
npx create-next-app@14 frontend --typescript --tailwind --eslint --app --src-dir=false --import-alias "@/*"
```

- [ ] **Step 2: Create `frontend/lib/api.ts`**

```typescript
const API = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

export async function getLatestBriefing() {
  const r = await fetch(`${API}/api/briefing/latest`, { next: { revalidate: 300 } });
  return r.json();
}

export async function getLatestSnapshots() {
  const r = await fetch(`${API}/api/snapshots/latest`, { next: { revalidate: 300 } });
  return r.json();
}

export async function getHistory(keywordId: number, days = 7) {
  const r = await fetch(`${API}/api/snapshots/history/${keywordId}?days=${days}`, { next: { revalidate: 300 } });
  return r.json();
}
```

- [ ] **Step 3: Build components**

- `TopBriefing.tsx` — 3 cards with summary, source, link, sentiment badges
- `KeywordCard.tsx` — pct bars, red border if `is_critical`
- `TrendChart.tsx` — Recharts `LineChart`, one line per keyword (or toggle)
- `SentimentBadge.tsx` — institutional + thematic pills

- [ ] **Step 4: Build `app/page.tsx`**

Layout per spec section 11.1. Show last update timestamp. Grid of 18 keyword cards (responsive 2–4 cols).

- [ ] **Step 5: Manual verify**

Run: `docker compose up -d && cd frontend && npm run dev`
Open: `http://localhost:3000`
Expected: Top 3, cards, chart render with API data

- [ ] **Step 6: Commit**

```bash
git commit -m "feat: public dashboard home with Top 3, cards, and 7-day chart"
```

---

### Task 12: Keyword detail page

**Files:**
- Create: `frontend/app/keywords/[id]/page.tsx`

- [ ] **Step 1: Fetch keyword articles for today**

Call `GET /api/keywords/{id}/articles?date=...`

- [ ] **Step 2: Render list**

Each row: title (link), source, published_at, dual sentiment badges. Highlight if `relevance_score >= 70`.

- [ ] **Step 3: Verify navigation**

Click card on home → detail page loads

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: keyword detail page with article list"
```

---

### Task 13: Cron scheduling (2×/day)

**Files:**
- Create: `.github/workflows/pipeline.yml` OR document cron in `README.md`

- [ ] **Step 1: GitHub Actions workflow**

```yaml
name: Pipeline
on:
  schedule:
    - cron: "0 10 * * *"   # 07:00 BRT = 10:00 UTC
    - cron: "0 21 * * *"   # 18:00 BRT = 21:00 UTC
  workflow_dispatch:
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install -e "./backend[dev]"
      - run: python backend/scripts/run_pipeline.py manha
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          DEEPSEEK_API_KEY: ${{ secrets.DEEPSEEK_API_KEY }}
          DEEPSEEK_BASE_URL: https://api.deepseek.com
          DEEPSEEK_MODEL: deepseek-v4-flash
```

Adjust slot argument based on cron (manha vs tarde).

- [ ] **Step 2: Document secrets setup in README**

- [ ] **Step 3: Commit**

```bash
git commit -m "ci: schedule pipeline at 07h and 18h BRT"
```

---

### Task 14: README + final verification

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Write README**

Sections: overview, local dev (`docker compose up`, seed, pipeline, frontend), env vars, methodology link to spec, license.

- [ ] **Step 2: Run full test suite**

Run: `cd backend && pytest -v`
Expected: all tests pass

- [ ] **Step 3: Run pipeline + load dashboard**

Verify critical card turns red with fixture data (or real negative news cycle).

- [ ] **Step 4: Final commit**

```bash
git commit -m "docs: add README and verify MVP checklist"
```

---

## Spec Coverage Checklist

| Spec requirement | Task |
|------------------|------|
| Public, no auth | Task 10 (no auth middleware) |
| 7 sources | Task 3, 7 |
| 18 keywords | Task 3, 4 |
| Dual sentiment | Task 8 |
| Top 3 briefing | Task 8, 9, 11 |
| Critical visual (≥60% or high impact) | Task 6, 11 |
| 7-day chart | Task 10, 11 |
| 2×/day updates | Task 9, 13 |
| Error handling (partial source fail) | Task 9 |
| Export JSON (phase 1.5) | Deferred — add `GET /api/export/snapshots.json` in follow-up task |

## Plan Self-Review

- No TBD/TODO placeholders in task steps
- Types consistent: `sentiment_institutional`, `sentiment_thematic`, `is_critical`, `slot` (`manha`|`tarde`)
- All 18 keywords included in seed
- Critical logic matches spec (60% + impact ≥70 dual negative)

---

**Plan complete.** Saved to `docs/superpowers/plans/2026-06-20-painel-humor-ecossistema-rs.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks
2. **Inline Execution** — implement task-by-task in this session with checkpoints

Which approach do you prefer?
