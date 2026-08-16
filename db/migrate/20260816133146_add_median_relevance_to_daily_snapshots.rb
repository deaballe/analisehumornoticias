class AddMedianRelevanceToDailySnapshots < ActiveRecord::Migration[8.1]
  def change
    add_column :daily_snapshots, :median_relevance, :decimal, precision: 5, scale: 2, null: false, default: 0
  end
end
