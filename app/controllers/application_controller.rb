class ApplicationController < ActionController::Base
  include Pagy::Method

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :authenticate_org_user!

  helper_method :current_organisation

  around_action :set_time_zone

  def current_organisation
    @current_organisation ||= current_user&.organisation
  end

  private

  def authenticate_org_user!
    authenticate_user!

    if current_user.super_admin?
      render plain: "Super admin must use /super routes.", status: :forbidden
      return
    end

    @organisation = current_organisation
  end

  def check_org_admin!
    if current_user.org_member?
      render plain: "Forbidden", status: :forbidden
    end
  end

  def set_time_zone(&block)
    Time.use_zone("UTC", &block)
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
