class DailySummaryJob < ApplicationJob
  queue_as :default

  def perform
    yesterday = Date.yesterday
    events = DetectionEvent.where(detected_at: yesterday.all_day)
                           .group(:organisation_id, :employee_id, :ai_tool_id)
                           .count

    rows = events.map do |(org_id, emp_id, tool_id), count|
      {
        organisation_id: org_id,
        employee_id: emp_id,
        ai_tool_id: tool_id,
        summary_date: yesterday,
        session_count: count,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    if rows.any?
      DailySummary.upsert_all(
        rows,
        unique_by: :idx_daily_summaries_unique,
        update_only: [:session_count]
      )
    end

    org_count = rows.map { |r| r[:organisation_id] }.uniq.count
    Rails.logger.info "DailySummaryJob: #{rows.size} rows upserted for #{org_count} orgs (#{yesterday})"
  end
end
