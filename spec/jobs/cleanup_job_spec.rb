require "rails_helper"

RSpec.describe CleanupJob, type: :job do
  let(:org) { create(:organisation) }
  let(:employee) { create(:employee, organisation: org) }
  let(:ai_tool) { org.ai_tools.first }

  it "deletes events older than 90 days" do
    old_event = create(:detection_event, organisation: org, employee: employee, ai_tool: ai_tool, detected_at: 91.days.ago)
    CleanupJob.perform_now
    expect(DetectionEvent.exists?(old_event.id)).to be false
  end

  it "deletes events exactly 90 days old" do
    event_90 = create(:detection_event, organisation: org, employee: employee, ai_tool: ai_tool, detected_at: 90.days.ago)
    CleanupJob.perform_now
    expect(DetectionEvent.exists?(event_90.id)).to be false
  end

  it "keeps events 89 days old" do
    recent_event = create(:detection_event, organisation: org, employee: employee, ai_tool: ai_tool, detected_at: 89.days.ago)
    CleanupJob.perform_now
    expect(DetectionEvent.exists?(recent_event.id)).to be true
  end

  it "does not delete DailySummary records" do
    create(:daily_summary, organisation: org, employee: employee, ai_tool: ai_tool, summary_date: 100.days.ago)
    CleanupJob.perform_now
    expect(DailySummary.count).to eq(1)
  end
end
