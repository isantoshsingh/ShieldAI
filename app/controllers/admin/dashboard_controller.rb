module Admin
  class DashboardController < BaseController
    def index
      @total_organisations = Organisation.count
      @total_employees = Employee.count
      @total_events_30d = DetectionEvent.where(detected_at: 30.days.ago..).count
      @organisations = Organisation.all.order(created_at: :desc)
    end
  end
end
