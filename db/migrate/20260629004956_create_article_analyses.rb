class CreateArticleAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :article_analyses do |t|
      t.references :article, null: false, foreign_key: true
      t.references :keyword, null: false, foreign_key: true
      t.string :sentiment_institutional, null: false
      t.string :sentiment_thematic, null: false
      t.integer :relevance_score, null: false

      t.timestamps
    end
    add_index :article_analyses, [ :article_id, :keyword_id ], unique: true
  end
end
