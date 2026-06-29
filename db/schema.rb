# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_29_004958) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "article_analyses", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.bigint "keyword_id", null: false
    t.integer "relevance_score", null: false
    t.string "sentiment_institutional", null: false
    t.string "sentiment_thematic", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "keyword_id"], name: "index_article_analyses_on_article_id_and_keyword_id", unique: true
    t.index ["article_id"], name: "index_article_analyses_on_article_id"
    t.index ["keyword_id"], name: "index_article_analyses_on_keyword_id"
  end

  create_table "articles", force: :cascade do |t|
    t.text "content_snippet"
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.bigint "source_id", null: false
    t.text "title", null: false
    t.datetime "updated_at", null: false
    t.text "url", null: false
    t.index ["source_id"], name: "index_articles_on_source_id"
    t.index ["url"], name: "index_articles_on_url", unique: true
  end

  create_table "daily_briefings", force: :cascade do |t|
    t.date "briefing_date", null: false
    t.datetime "created_at", null: false
    t.jsonb "items", default: [], null: false
    t.string "slot", null: false
    t.datetime "updated_at", null: false
    t.index ["briefing_date", "slot"], name: "index_daily_briefings_on_briefing_date_and_slot", unique: true
  end

  create_table "daily_snapshots", force: :cascade do |t|
    t.integer "article_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.boolean "is_critical", default: false, null: false
    t.bigint "keyword_id", null: false
    t.decimal "pct_negative", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "pct_neutral", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "pct_positive", precision: 5, scale: 2, default: "0.0", null: false
    t.string "slot", null: false
    t.date "snapshot_date", null: false
    t.datetime "updated_at", null: false
    t.index ["keyword_id"], name: "index_daily_snapshots_on_keyword_id"
    t.index ["snapshot_date", "slot", "keyword_id"], name: "idx_snapshots_date_slot_keyword", unique: true
  end

  create_table "keywords", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "synonyms", default: [], array: true
    t.string "term", null: false
    t.datetime "updated_at", null: false
    t.index ["term"], name: "index_keywords_on_term", unique: true
  end

  create_table "sources", force: :cascade do |t|
    t.text "base_url", null: false
    t.datetime "created_at", null: false
    t.jsonb "fetch_config", default: {}, null: false
    t.string "fetch_type", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_sources_on_slug", unique: true
  end

  add_foreign_key "article_analyses", "articles"
  add_foreign_key "article_analyses", "keywords"
  add_foreign_key "articles", "sources"
  add_foreign_key "daily_snapshots", "keywords"
end
