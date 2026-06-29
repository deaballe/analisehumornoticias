class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :base_url, null: false
      t.string :fetch_type, null: false
      t.jsonb :fetch_config, null: false, default: {}

      t.timestamps
    end
    add_index :sources, :slug, unique: true
  end
end
