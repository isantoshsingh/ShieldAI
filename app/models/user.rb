class User < ApplicationRecord
  has_many :events, dependent: :destroy
  has_many :magic_links, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :token, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[member admin] }

  before_validation :generate_token, on: :create
  before_save :downcase_email

  scope :admins, -> { where(role: "admin") }
  scope :members, -> { where(role: "member") }

  def admin?
    role == "admin"
  end

  def event_count_last_30_days
    events.where("detected_at >= ?", 30.days.ago).count
  end

  def unique_tools_count
    events.select(:ai_tool_id).distinct.count
  end

  def last_seen
    events.order(detected_at: :desc).first&.detected_at
  end

  def first_seen
    events.order(detected_at: :asc).first&.detected_at
  end

  private

  def generate_token
    self.token ||= "usr_#{SecureRandom.hex(16)}"
  end

  def downcase_email
    self.email = email.downcase if email
  end
end
