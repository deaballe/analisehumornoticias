class CreateKeywords < ActiveRecord::Migration[8.1]
  def change
    create_table :keywords do |t|
      t.string :term, null: false
      t.string :synonyms, array: true, default: []

      t.timestamps
    end
    add_index :keywords, :term, unique: true
  end
end
