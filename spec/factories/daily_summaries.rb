FactoryBot.define do
  factory :daily_summary do
    organisation
    employee
    ai_tool
    summary_date { Date.yesterday }
    session_count { 5 }
  end
end
