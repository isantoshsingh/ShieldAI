class AiTool < ApplicationRecord
  has_many :events, dependent: :nullify

  validates :name, presence: true
  validates :domain, presence: true, uniqueness: true
  validates :risk_level, inclusion: { in: %w[low medium high] }
  validates :category, inclusion: { in: %w[chat code writing image search other] }, allow_nil: true

  scope :approved, -> { where(approved: true) }
  scope :unapproved, -> { where(approved: false) }
  scope :by_usage, -> { left_joins(:events).group(:id).order("COUNT(events.id) DESC") }

  def total_events
    events.count
  end

  def unique_users_count
    events.select(:user_id).distinct.count
  end

  def first_detected
    events.order(detected_at: :asc).first&.detected_at
  end
end
