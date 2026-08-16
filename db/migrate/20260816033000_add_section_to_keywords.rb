class AddSectionToKeywords < ActiveRecord::Migration[8.1]
  def change
    add_column :keywords, :section, :string, null: false, default: "temas"
    add_index :keywords, :section
  end
end
