class Employee < ApplicationRecord
  belongs_to :organisation
  has_many :detection_events, dependent: :destroy
  has_many :daily_summaries, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { scope: :organisation_id, case_sensitive: false }
  validates :extension_token, presence: true, uniqueness: true

  before_validation :generate_extension_token, on: :create

  def risk_level
    @risk_level ||= begin
      count = detection_events
        .joins(ai_tool: :organisation_ai_tools)
        .where(organisation_ai_tools: { organisation_id: organisation_id, approved: false })
        .count
      if count >= 3
        "high"
      elsif count >= 1
        "medium"
      else
        "low"
      end
    end
  end

  private

  def generate_extension_token
    self.extension_token = SecureRandom.urlsafe_base64(32)
  end
end
