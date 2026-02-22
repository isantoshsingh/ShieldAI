class AuthController < ApplicationController
  skip_before_action :require_login!, only: [:login, :send_link, :magic_login]

  def login
    # GET /auth/login — show email form
  end

  def send_link
    email = params[:email].to_s.strip.downcase

    if email.blank?
      flash[:alert] = "Please enter your email address."
      return redirect_to login_path
    end

    user = User.find_by(email: email)
    unless user
      # Don't reveal whether email exists — show generic message
      flash[:notice] = "If that email is registered, you'll receive a login link shortly."
      return redirect_to login_path
    end

    link = MagicLink.create!(
      user:       user,
      expires_at: 15.minutes.from_now
    )

    AuthMailer.magic_link(user, link).deliver_later

    flash[:notice] = "Login link sent! Check your email (link expires in 15 minutes)."
    redirect_to login_path
  end

  def magic_login
    link = MagicLink.find_by(token: params[:token])

    if link.nil? || !link.valid_for_login?
      flash[:alert] = "This login link is invalid or has expired. Please request a new one."
      return redirect_to login_path
    end

    link.consume!
    session[:user_id] = link.user_id

    redirect_to root_path, notice: "Welcome back, #{link.user.name}!"
  end

  def logout
    session.delete(:user_id)
    redirect_to login_path, notice: "You've been logged out."
  end
end
