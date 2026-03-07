class EmployeesController < ApplicationController
  before_action :check_org_admin!, only: [:new, :create, :destroy, :regenerate_token]

  def index
    @employees = current_organisation.employees.includes(detection_events: :ai_tool)
    if params[:search].present?
      search = "%#{params[:search]}%"
      @employees = @employees.where("name ILIKE ? OR email ILIKE ?", search, search)
    end
    if params[:department].present?
      @employees = @employees.where(department: params[:department])
    end
    if params[:status] == "all"
      # show all
    else
      @employees = @employees.where(active: true)
    end

    @employees = @employees.order(created_at: :desc)
    @pagy, @employees = pagy(:offset, @employees, limit: 25)
    @departments = current_organisation.employees.distinct.pluck(:department).compact.sort
  end

  def show
    @employee = current_organisation.employees.find(params[:id])
    @events = @employee.detection_events.includes(:ai_tool).recent.limit(20)
    @tools_used = @employee.detection_events.joins(:ai_tool)
                           .group("ai_tools.name", "ai_tools.icon_emoji", "ai_tools.approved")
                           .count
  end

  def new
    @employee = current_organisation.employees.build
  end

  def create
    @employee = current_organisation.employees.build(employee_params)
    if @employee.save
      redirect_to employees_path, notice: "Employee created. Token: #{@employee.extension_token}. Copy it now — this is the only time it will be shown in full."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @employee = current_organisation.employees.find(params[:id])
    @employee.update!(active: false)
    redirect_to employees_path, notice: "Employee deactivated."
  end

  def regenerate_token
    @employee = current_organisation.employees.find(params[:id])
    new_token = SecureRandom.urlsafe_base64(32)
    @employee.update!(extension_token: new_token)
    redirect_to employee_path(@employee), notice: "Token regenerated. New token: #{new_token}. Copy it now — this is the only time it will be shown in full."
  end

  def more_events
    @employee = current_organisation.employees.find(params[:id])
    @offset = (params[:offset] || 0).to_i
    @events = @employee.detection_events.includes(:ai_tool).recent.offset(@offset).limit(20)
    render layout: false
  end

  private

  def employee_params
    params.require(:employee).permit(:name, :email, :department)
  end
end
