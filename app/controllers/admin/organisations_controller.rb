module Admin
  class OrganisationsController < BaseController
    def index
      @pagy, @organisations = pagy(:offset, Organisation.left_joins(:employees).select("organisations.*, COUNT(employees.id) AS employees_count").group("organisations.id").order(created_at: :desc), limit: 25)
    end

    def show
      @organisation = Organisation.find(params[:id])
      @employees = @organisation.employees
      @ai_tools = @organisation.ai_tools
      @users = @organisation.users
      @recent_events = @organisation.detection_events.includes(:employee, :ai_tool).recent.limit(20)
    end

    def new
      @organisation = Organisation.new
      @user = User.new
    end

    def create
      @organisation = Organisation.new(organisation_params)
      @user = User.new(user_params.merge(role: "org_admin"))

      ActiveRecord::Base.transaction do
        @organisation.save!
        @user.organisation = @organisation
        @user.save!
      end

      redirect_to admin_organisation_path(@organisation), notice: "Organisation created."
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    private

    def organisation_params
      params.require(:organisation).permit(:name)
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
  end
end
