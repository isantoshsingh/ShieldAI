class UsersController < ApplicationController
  def index
    @users = User.all

    if params[:search].present?
      query = "%#{params[:search].downcase}%"
      @users = @users.where("LOWER(email) LIKE ? OR LOWER(name) LIKE ?", query, query)
    end

    sort_column    = %w[name email department].include?(params[:sort]) ? params[:sort] : nil
    @users = if sort_column
               @users.order(sort_column)
             else
               # Default: sort by event count (30d)
               @users.left_joins(:events)
                     .where("events.detected_at >= ? OR events.id IS NULL", 30.days.ago)
                     .group("users.id")
                     .order("COUNT(events.id) DESC")
             end
  end

  def show
    @user = User.find(params[:id])

    @events_by_date = @user.events
                           .includes(:ai_tool)
                           .order(detected_at: :desc)
                           .group_by { |e| e.detected_at.to_date }

    @tools_used = AiTool.joins(:events)
                        .where(events: { user: @user })
                        .group("ai_tools.id")
                        .order("COUNT(events.id) DESC")
                        .select("ai_tools.*, COUNT(events.id) AS events_count")
  end
end
