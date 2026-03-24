FactoryBot.define do
  factory :organisation do
    sequence(:name) { |n| "Organisation #{n}" }
  end
end
