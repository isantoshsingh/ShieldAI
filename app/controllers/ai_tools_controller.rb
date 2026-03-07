class AiToolsController < ApplicationController
  before_action :check_org_admin!, only: [:toggle_approved, :create]

  def index
    @ai_tools = current_organisation.ai_tools
                  .left_joins(:detection_events)
                  .select("ai_tools.*, COUNT(detection_events.id) AS total_sessions, COUNT(DISTINCT detection_events.employee_id) AS unique_employees")
                  .group("ai_tools.id")
                  .order("total_sessions DESC")
  end

  def create
    @ai_tool = current_organisation.ai_tools.build(ai_tool_params)
    if @ai_tool.save
      redirect_to ai_tools_path, notice: "AI Tool added."
    else
      @ai_tools = current_organisation.ai_tools
      render :index, status: :unprocessable_entity
    end
  end

  def toggle_approved
    @ai_tool = current_organisation.ai_tools.find(params[:id])
    @ai_tool.update!(approved: !@ai_tool.approved)
    respond_to do |format|
      format.html { redirect_to ai_tools_path }
      format.turbo_stream
    end
  end

  private

  def ai_tool_params
    params.require(:ai_tool).permit(:name, :domain, :category, :approved)
  end
end
