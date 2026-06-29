class Keyword < ApplicationRecord
  has_many :article_analyses, dependent: :destroy
  has_many :daily_snapshots, dependent: :destroy

  validates :term, presence: true, uniqueness: true
end
