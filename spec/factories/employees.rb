FactoryBot.define do
  factory :employee do
    organisation
    sequence(:name) { |n| "Employee #{n}" }
    sequence(:email) { |n| "employee#{n}@example.com" }
    department { "Engineering" }
    active { true }
  end
end
