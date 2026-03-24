class DailySummary < ApplicationRecord
  belongs_to :organisation
  belongs_to :employee
  belongs_to :ai_tool

  validates :summary_date, presence: true
  validates :session_count, numericality: { greater_than_or_equal_to: 0 }
end
