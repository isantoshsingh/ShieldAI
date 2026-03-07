FactoryBot.define do
  factory :ai_tool do
    sequence(:name) { |n| "AI Tool #{n}" }
    sequence(:domain) { |n| "tool#{n}.example.com" }
    category { "chat" }
    icon_emoji { "\u{1F916}" }
  end
end
