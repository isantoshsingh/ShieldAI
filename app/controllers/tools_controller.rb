class ToolsController < ApplicationController
  def index
    @tools = AiTool.left_joins(:events)
                   .group(:id)
                   .order("COUNT(events.id) DESC")
                   .select("ai_tools.*, COUNT(events.id) AS total_events_count, COUNT(DISTINCT events.user_id) AS unique_users_count")
  end
end
