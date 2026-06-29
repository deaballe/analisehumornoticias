class Article < ApplicationRecord
  belongs_to :source
  has_many :article_analyses, dependent: :destroy

  validates :title, :url, presence: true
  validates :url, uniqueness: true
end
