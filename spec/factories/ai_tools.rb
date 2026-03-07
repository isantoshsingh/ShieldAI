FactoryBot.define do
  factory :ai_tool do
    organisation
    sequence(:name) { |n| "AI Tool #{n}" }
    sequence(:domain) { |n| "tool#{n}.example.com" }
    category { "chat" }
    icon_emoji { "🤖" }
    approved { false }
  end
end
