class AiTool < ApplicationRecord
  CATEGORIES = %w[chat code image search writing other].freeze

  belongs_to :organisation
  has_many :detection_events
  has_many :daily_summaries

  validates :name, presence: true
  validates :domain, presence: true, uniqueness: { scope: :organisation_id, case_sensitive: false }
  validates :category, inclusion: { in: CATEGORIES }

  before_save :normalize_domain

  private

  def normalize_domain
    self.domain = domain.downcase.strip
  end
end
