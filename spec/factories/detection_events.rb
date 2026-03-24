FactoryBot.define do
  factory :detection_event do
    organisation
    employee
    ai_tool
    detected_at { Time.current }
    page_title { "Test Page" }
  end
end
