class CreateDailyBriefings < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_briefings do |t|
      t.date :briefing_date, null: false
      t.string :slot, null: false
      t.jsonb :items, null: false, default: []

      t.timestamps
    end
    add_index :daily_briefings, [ :briefing_date, :slot ], unique: true
  end
end
