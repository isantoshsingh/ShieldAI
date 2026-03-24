class ReportsController < ApplicationController
  before_action :check_org_admin!, only: [:export]

  def index
    @start_date = parse_date(params[:start_date], 30.days.ago.to_date)
    @end_date = parse_date(params[:end_date], Date.today)
    @events = current_organisation.detection_events.where(detected_at: @start_date.beginning_of_day..@end_date.end_of_day)

    @top_tools = @events.joins(:ai_tool)
                        .group("ai_tools.name")
                        .select("ai_tools.name, COUNT(*) AS sessions, COUNT(DISTINCT detection_events.employee_id) AS unique_employees")
                        .order("sessions DESC")
                        .limit(10)

    @top_employees = @events.joins(:employee)
                            .group("employees.name", "employees.department")
                            .select("employees.name, employees.department, COUNT(*) AS sessions")
                            .order("sessions DESC")
                            .limit(10)
  end

  def export
    @start_date = parse_date(params[:start_date], 30.days.ago.to_date)
    @end_date = parse_date(params[:end_date], Date.today)

    CsvExportJob.perform_later(current_user.id, current_organisation.id, @start_date.to_s, @end_date.to_s)
    redirect_to reports_path(start_date: @start_date, end_date: @end_date),
                notice: "Your report is being generated and will be emailed to #{current_user.email}."
  end

  private

  def parse_date(str, default)
    Date.parse(str)
  rescue ArgumentError, TypeError
    default
  end
end
