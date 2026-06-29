class Source < ApplicationRecord
  has_many :articles, dependent: :destroy

  validates :slug, :name, :base_url, :fetch_type, presence: true
  validates :slug, uniqueness: true
end
