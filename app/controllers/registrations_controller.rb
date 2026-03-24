class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :authenticate_org_user!

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

    sign_in(@user)
    redirect_to root_path, notice: "Welcome to ShieldAI. Your organisation has been created."
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
