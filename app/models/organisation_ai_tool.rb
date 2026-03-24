class OrganisationAiTool < ApplicationRecord
  belongs_to :organisation
  belongs_to :ai_tool

  validates :ai_tool_id, uniqueness: { scope: :organisation_id }
end
