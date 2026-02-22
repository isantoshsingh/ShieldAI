module Api
  module V1
    class EventsController < ActionController::API
      def create
        token = params[:token]
        user  = User.find_by(token: token)

        return render json: { error: "Unauthorized" }, status: :unauthorized unless user

        event_params = params.require(:event).permit(:domain, :page_title, :detected_at, :session_id)

        event = user.events.create!(
          domain:      event_params[:domain],
          page_title:  event_params[:page_title],
          detected_at: event_params[:detected_at] || Time.current,
          session_id:  event_params[:session_id]
        )

        render json: { status: "ok", event_id: event.id }
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
