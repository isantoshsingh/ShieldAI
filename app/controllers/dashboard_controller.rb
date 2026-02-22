class DashboardController < ApplicationController
  def index
    @total_events_today    = Event.today.count
    @unique_tools_today    = Event.today.select(:ai_tool_id).distinct.count
    @active_users_today    = Event.today.select(:user_id).distinct.count
    @most_used_tool        = AiTool.left_joins(:events)
                                   .where("events.detected_at >= ?", Time.current.beginning_of_day)
                                   .group(:id)
                                   .order("COUNT(events.id) DESC")
                                   .first

    @recent_events = Event.includes(:user, :ai_tool)
                          .order(detected_at: :desc)
                          .limit(50)

    @top_tools = AiTool.left_joins(:events)
                       .group(:id)
                       .order("COUNT(events.id) DESC")
                       .limit(10)
                       .select("ai_tools.*, COUNT(events.id) AS events_count")

    @department_stats = Event.joins(:user)
                             .where("events.detected_at >= ?", 30.days.ago)
                             .group("users.department")
                             .order("COUNT(events.id) DESC")
                             .count
  end
end
