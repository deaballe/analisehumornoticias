class CreateDailySnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_snapshots do |t|
      t.date :snapshot_date, null: false
      t.string :slot, null: false
      t.references :keyword, null: false, foreign_key: true
      t.decimal :pct_positive, precision: 5, scale: 2, null: false, default: 0
      t.decimal :pct_neutral, precision: 5, scale: 2, null: false, default: 0
      t.decimal :pct_negative, precision: 5, scale: 2, null: false, default: 0
      t.integer :article_count, null: false, default: 0
      t.boolean :is_critical, null: false, default: false

      t.timestamps
    end
    add_index :daily_snapshots, [ :snapshot_date, :slot, :keyword_id ],
              unique: true, name: "idx_snapshots_date_slot_keyword"
  end
end
