class AiToolsController < ApplicationController
  before_action :check_org_admin!, only: [:toggle_approved, :create]

  def index
    @org_ai_tools = OrganisationAiTool
                      .where(organisation_id: current_organisation.id)
                      .joins(:ai_tool)
                      .left_joins(ai_tool: :detection_events)
                      .select(
                        "organisation_ai_tools.id AS org_ai_tool_id",
                        "organisation_ai_tools.approved",
                        "ai_tools.*",
                        "COUNT(detection_events.id) AS total_sessions",
                        "COUNT(DISTINCT detection_events.employee_id) AS unique_employees"
                      )
                      .group("organisation_ai_tools.id", "ai_tools.id")
                      .order("total_sessions DESC")
  end

  def create
    ai_tool = AiTool.find_or_initialize_by(domain: ai_tool_params[:domain]&.downcase&.strip)
    ai_tool.assign_attributes(ai_tool_params.except(:approved))

    ActiveRecord::Base.transaction do
      ai_tool.save!
      OrganisationAiTool.find_or_create_by!(
        organisation: current_organisation,
        ai_tool: ai_tool
      ) do |oat|
        oat.approved = ai_tool_params[:approved] == "1"
      end
    end

    redirect_to ai_tools_path, notice: "AI Tool added."
  rescue ActiveRecord::RecordInvalid
    @org_ai_tools = current_organisation.organisation_ai_tools.joins(:ai_tool)
    render :index, status: :unprocessable_entity
  end

  def toggle_approved
    @org_ai_tool = current_organisation.organisation_ai_tools.find_by!(ai_tool_id: params[:id])
    @org_ai_tool.update!(approved: !@org_ai_tool.approved)
    @ai_tool = @org_ai_tool.ai_tool
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
