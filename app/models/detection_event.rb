class DetectionEvent < ApplicationRecord
  belongs_to :organisation
  belongs_to :employee
  belongs_to :ai_tool

  validates :detected_at, presence: true

  scope :recent, -> { order(detected_at: :desc) }
  scope :today, -> { where(detected_at: Time.current.all_day) }
  scope :last_days, ->(n) { where(detected_at: n.days.ago.beginning_of_day..) }
  scope :unapproved, -> {
    joins(ai_tool: :organisation_ai_tools)
      .where("organisation_ai_tools.organisation_id = detection_events.organisation_id")
      .where(organisation_ai_tools: { approved: false })
  }
end
