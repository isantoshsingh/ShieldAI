FactoryBot.define do
  factory :organisation_ai_tool do
    organisation
    ai_tool
    approved { false }
  end
end
