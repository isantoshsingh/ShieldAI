require "csv"

class CsvExportJob < ApplicationJob
  queue_as :default

  def perform(user_id, organisation_id, start_date, end_date)
    user = User.find_by(id: user_id)
    organisation = Organisation.find_by(id: organisation_id)

    if user.nil? || organisation.nil?
      Rails.logger.warn "CsvExportJob: user or organisation not found (user_id=#{user_id}, org_id=#{organisation_id})"
      return
    end

    events = organisation.detection_events
                         .includes(:employee, :ai_tool)
                         .where(detected_at: Date.parse(start_date)..Date.parse(end_date).end_of_day)
                         .order(detected_at: :desc)

    csv_string = CSV.generate do |csv|
      csv << ["Date/Time", "Employee Name", "Employee Email", "Department", "AI Tool", "Category", "Approved"]
      events.each do |event|
        csv << [
          event.detected_at.strftime("%Y-%m-%d %H:%M:%S"),
          event.employee.name,
          event.employee.email,
          event.employee.department,
          event.ai_tool.name,
          event.ai_tool.category,
          event.ai_tool.approved? ? "Yes" : "No"
        ]
      end
    end

    filename = "shieldai_report_#{organisation.slug}_#{start_date}_#{end_date}.csv"
    CsvExportMailer.report(user, csv_string, filename, start_date, end_date).deliver_now
  end
end
