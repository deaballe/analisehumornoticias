class DailySnapshot < ApplicationRecord
  SLOTS = %w[manha tarde].freeze

  belongs_to :keyword

  validates :snapshot_date, :slot, presence: true
  validates :slot, inclusion: { in: SLOTS }
  validates :keyword_id, uniqueness: { scope: [ :snapshot_date, :slot ] }

  scope :latest_slot, -> {
    order(snapshot_date: :desc, slot: :desc)
  }

  def self.current
    latest_slot.first
  end
end
