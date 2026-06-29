class DailyBriefing < ApplicationRecord
  SLOTS = %w[manha tarde].freeze

  validates :briefing_date, :slot, presence: true
  validates :slot, inclusion: { in: SLOTS }
  validates :briefing_date, uniqueness: { scope: :slot }

  scope :latest, -> { order(briefing_date: :desc, slot: :desc) }

  def self.current
    latest.first
  end
end
