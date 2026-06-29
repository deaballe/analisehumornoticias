class ArticleAnalysis < ApplicationRecord
  SENTIMENTS = %w[positive neutral negative].freeze

  belongs_to :article
  belongs_to :keyword

  validates :sentiment_institutional, :sentiment_thematic, presence: true
  validates :sentiment_institutional, inclusion: { in: SENTIMENTS }
  validates :sentiment_thematic, inclusion: { in: SENTIMENTS }
  validates :relevance_score, presence: true, numericality: { in: 0..100 }
  validates :keyword_id, uniqueness: { scope: :article_id }

  scope :high_impact, -> { where("relevance_score >= ?", 70) }
end
