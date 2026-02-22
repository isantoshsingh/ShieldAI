class Event < ApplicationRecord
  belongs_to :user
  belongs_to :ai_tool, optional: true

  validates :domain, presence: true
  validates :detected_at, presence: true

  before_create :associate_ai_tool

  scope :recent, -> { order(detected_at: :desc) }
  scope :today, -> { where("detected_at >= ?", Time.current.beginning_of_day) }
  scope :last_7_days, -> { where("detected_at >= ?", 7.days.ago) }
  scope :last_30_days, -> { where("detected_at >= ?", 30.days.ago) }

  def tool_name
    ai_tool&.name || domain
  end

  private

  def associate_ai_tool
    self.ai_tool ||= AiTool.find_by(domain: domain)
  end
end
