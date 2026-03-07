module Admin
  class DashboardController < BaseController
    def index
      @total_organisations = Organisation.count
      @total_employees = Employee.count
      @total_events_30d = DetectionEvent.where(detected_at: 30.days.ago..).count
      cutoff = 30.days.ago
      @organisations = Organisation
                         .left_joins(:employees, :detection_events)
                         .select(
                           "organisations.*",
                           "COUNT(DISTINCT employees.id) AS employees_count",
                           Arel.sql(ActiveRecord::Base.sanitize_sql_array(
                             ["COUNT(DISTINCT CASE WHEN detection_events.detected_at >= ? THEN detection_events.id END) AS events_30d_count", cutoff]
                           ))
                         )
                         .group("organisations.id")
                         .order(created_at: :desc)
    end
  end
end
