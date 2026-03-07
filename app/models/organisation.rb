class Organisation < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :ai_tools, dependent: :destroy
  has_many :detection_events, dependent: :destroy
  has_many :daily_summaries, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create
  after_create :seed_ai_tools

  private

  def generate_slug
    return if name.blank?

    base_slug = name.parameterize
    self.slug = base_slug

    if Organisation.exists?(slug: slug)
      self.slug = "#{base_slug}-#{SecureRandom.hex(2)}"
    end
  end

  def seed_ai_tools
    tools_data = YAML.load_file(Rails.root.join("config/ai_tools_seed.yml"))
    now = Time.current

    rows = tools_data.map do |tool|
      {
        organisation_id: id,
        name: tool["name"],
        domain: tool["domain"],
        category: tool["category"],
        icon_emoji: tool["icon_emoji"] || "🤖",
        approved: false,
        created_at: now,
        updated_at: now
      }
    end

    AiTool.insert_all(rows) if rows.any?
  end
end
