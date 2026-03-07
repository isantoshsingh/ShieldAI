class Organisation < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :organisation_ai_tools, dependent: :destroy
  has_many :ai_tools, through: :organisation_ai_tools
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

    tools_data.each do |tool|
      ai_tool = AiTool.find_or_create_by!(domain: tool["domain"].downcase.strip) do |t|
        t.name = tool["name"]
        t.category = tool["category"]
        t.icon_emoji = tool["icon_emoji"] || "\u{1F916}"
      end

      OrganisationAiTool.create!(
        organisation: self,
        ai_tool: ai_tool,
        approved: false
      )
    end
  end
end
