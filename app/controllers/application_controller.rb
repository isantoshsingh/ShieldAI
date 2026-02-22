class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :require_login!

  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login!
    unless logged_in?
      flash[:alert] = "Please log in to continue."
      redirect_to login_path
    end
  end

  def require_admin!
    unless current_user&.admin?
      flash[:alert] = "Access denied."
      redirect_to root_path
    end
  end
end
