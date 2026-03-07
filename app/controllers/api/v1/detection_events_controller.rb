module Api
  module V1
    class DetectionEventsController < ActionController::Base
      skip_forgery_protection
      skip_before_action :authenticate_user!, raise: false
      skip_before_action :authenticate_org_user!, raise: false

      def create
        employee = Employee.find_by(extension_token: params[:token])

        if employee.nil? || !employee.active?
          render json: { error: "invalid token" }, status: :unauthorized
          return
        end

        organisation = employee.organisation

        ai_tool = organisation.ai_tools.find_by(domain: params[:domain].to_s.downcase)
        if ai_tool.nil?
          render json: { error: "unknown domain" }, status: :unprocessable_entity
          return
        end

        detected_at = begin
          Time.parse(params[:detected_at])
        rescue ArgumentError, TypeError
          Time.current
        end

        DetectionEvent.create!(
          organisation_id: organisation.id,
          employee_id: employee.id,
          ai_tool_id: ai_tool.id,
          page_title: params[:page_title].to_s.truncate(255),
          detected_at: detected_at
        )

        render json: { status: "ok" }, status: :created
      end
    end
  end
end
