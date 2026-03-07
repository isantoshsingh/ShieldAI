FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    role { "org_admin" }
    organisation

    trait :super_admin do
      role { "super_admin" }
      organisation { nil }
    end

    trait :org_admin do
      role { "org_admin" }
    end

    trait :org_member do
      role { "org_member" }
    end
  end
end
