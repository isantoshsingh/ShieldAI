class DashboardController < ApplicationController
  def index
    @total_sessions = current_organisation.detection_events.count
    @active_employees = current_organisation.employees.where(active: true).count
    @unique_tools = current_organisation.detection_events.select(:ai_tool_id).distinct.count
    @sessions_today = current_organisation.detection_events.where(detected_at: Date.today.all_day).count
    @recent_events = current_organisation.detection_events.includes(:employee, :ai_tool).recent.limit(20)
    @employees = current_organisation.employees.where(active: true).includes(detection_events: { ai_tool: :organisation_ai_tools })
  end
end
