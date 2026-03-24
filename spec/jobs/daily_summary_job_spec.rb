require "rails_helper"

RSpec.describe DailySummaryJob, type: :job do
  let(:org) { create(:organisation) }
  let(:employee) { create(:employee, organisation: org) }
  let(:ai_tool) { org.ai_tools.first }

  it "populates daily_summaries for yesterday's events" do
    create(:detection_event, organisation: org, employee: employee, ai_tool: ai_tool, detected_at: Date.yesterday.noon)
    create(:detection_event, organisation: org, employee: employee, ai_tool: ai_tool, detected_at: Date.yesterday.noon + 1.hour)

    expect {
      DailySummaryJob.perform_now
    }.to change(DailySummary, :count).by(1)

    summary = DailySummary.last
    expect(summary.organisation_id).to eq(org.id)
    expect(summary.employee_id).to eq(employee.id)
    expect(summary.ai_tool_id).to eq(ai_tool.id)
    expect(summary.summary_date).to eq(Date.yesterday)
    expect(summary.session_count).to eq(2)
  end

  it "upserts correctly on double-run" do
    create(:detection_event, organisation: org, employee: employee, ai_tool: ai_tool, detected_at: Date.yesterday.noon)

    DailySummaryJob.perform_now
    expect(DailySummary.count).to eq(1)
    expect(DailySummary.last.session_count).to eq(1)

    # Run again — should upsert not duplicate
    DailySummaryJob.perform_now
    expect(DailySummary.count).to eq(1)
    expect(DailySummary.last.session_count).to eq(1)
  end

  it "does not create rows for today's events" do
    create(:detection_event, organisation: org, employee: employee, ai_tool: ai_tool, detected_at: Time.current)

    DailySummaryJob.perform_now
    expect(DailySummary.count).to eq(0)
  end

  it "populates for all orgs" do
    org_b = create(:organisation)
    employee_b = create(:employee, organisation: org_b)
    tool_b = org_b.ai_tools.first

    create(:detection_event, organisation: org, employee: employee, ai_tool: ai_tool, detected_at: Date.yesterday.noon)
    create(:detection_event, organisation: org_b, employee: employee_b, ai_tool: tool_b, detected_at: Date.yesterday.noon)

    DailySummaryJob.perform_now
    expect(DailySummary.count).to eq(2)
    expect(DailySummary.where(organisation: org).count).to eq(1)
    expect(DailySummary.where(organisation: org_b).count).to eq(1)
  end
end
