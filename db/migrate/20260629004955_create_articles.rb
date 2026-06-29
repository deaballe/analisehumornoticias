class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.references :source, null: false, foreign_key: true
      t.text :title, null: false
      t.text :url, null: false
      t.datetime :published_at
      t.text :content_snippet

      t.timestamps
    end
    add_index :articles, :url, unique: true
  end
end
