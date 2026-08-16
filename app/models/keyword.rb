class Keyword < ApplicationRecord
  SECTIONS = %w[temas spgg_equipe].freeze

  has_many :article_analyses, dependent: :destroy
  has_many :daily_snapshots, dependent: :destroy

  validates :term, presence: true, uniqueness: true
  validates :section, presence: true, inclusion: { in: SECTIONS }

  scope :temas, -> { where(section: "temas") }
  scope :spgg_equipe, -> { where(section: "spgg_equipe") }
  scope :ordered, -> { order(:term) }
end
