class Article < ApplicationRecord
  belongs_to :source
  has_many :article_analyses, dependent: :destroy

  validates :title, :url, presence: true
  validates :url, uniqueness: true

  before_validation :clean_content_snippet

  def plain_snippet
    SnippetCleaner.call(content_snippet)
  end

  private

  def clean_content_snippet
    self.content_snippet = SnippetCleaner.call(content_snippet) if content_snippet.present?
  end
end
