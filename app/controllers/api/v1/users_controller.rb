module Api
  module V1
    class UsersController < ActionController::API
      skip_before_action :authenticate_token!, only: [:activate], raise: false

      def activate
        email = params[:email].to_s.strip.downcase

        if email.blank?
          return render json: { error: "Email is required" }, status: :unprocessable_entity
        end

        allowed_domain = ENV.fetch("ALLOWED_EMAIL_DOMAIN", nil)
        if allowed_domain.present? && !email.end_with?("@#{allowed_domain}")
          return render json: { error: "Email domain not allowed" }, status: :unprocessable_entity
        end

        user = User.find_or_create_by!(email: email) do |u|
          u.name = email.split("@").first.titleize
          u.role = "member"
        end

        render json: {
          token: user.token,
          name:  user.name,
          status: "active"
        }
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def me
        token = params[:token] || request.headers["X-Shield-Token"]
        user = User.find_by(token: token)

        return render json: { error: "Unauthorized" }, status: :unauthorized unless user

        render json: {
          name:          user.name,
          email:         user.email,
          events_7_days: user.events.last_7_days.count,
          status:        "active"
        }
      end
    end
  end
end
