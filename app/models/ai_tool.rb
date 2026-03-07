class AiTool < ApplicationRecord
  CATEGORIES = %w[chat code image search writing other].freeze

  has_many :organisation_ai_tools, dependent: :destroy
  has_many :organisations, through: :organisation_ai_tools
  has_many :detection_events
  has_many :daily_summaries

  validates :name, presence: true
  validates :domain, presence: true, uniqueness: { case_sensitive: false }
  validates :category, inclusion: { in: CATEGORIES }

  before_save :normalize_domain

  private

  def normalize_domain
    self.domain = domain.downcase.strip
  end
end
