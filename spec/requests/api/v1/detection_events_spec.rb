require "rails_helper"

RSpec.describe "API V1 Detection Events", type: :request do
  let(:organisation) { create(:organisation) }
  let(:employee) { create(:employee, organisation: organisation) }
  let(:ai_tool) { organisation.ai_tools.first || create(:ai_tool, organisation: organisation, domain: "chat.openai.com") }

  let(:valid_params) do
    {
      token: employee.extension_token,
      domain: ai_tool.domain,
      page_title: "Test Page Title",
      detected_at: "2026-03-06T10:30:00Z"
    }
  end

  describe "POST /api/v1/detection_events" do
    it "returns 201 and creates event for valid token+domain" do
      expect {
        post api_v1_detection_events_path, params: valid_params, as: :json
      }.to change(DetectionEvent, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["status"]).to eq("ok")
    end

    it "sets correct organisation_id, employee_id, ai_tool_id, detected_at" do
      post api_v1_detection_events_path, params: valid_params, as: :json

      event = DetectionEvent.last
      expect(event.organisation_id).to eq(organisation.id)
      expect(event.employee_id).to eq(employee.id)
      expect(event.ai_tool_id).to eq(ai_tool.id)
      expect(event.detected_at).to eq(Time.parse("2026-03-06T10:30:00Z"))
    end

    it "returns 401 for unknown token" do
      post api_v1_detection_events_path, params: valid_params.merge(token: "bad_token"), as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("invalid token")
    end

    it "returns 401 for inactive employee token" do
      employee.update!(active: false)

      post api_v1_detection_events_path, params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("invalid token")
    end

    it "returns 422 for unknown domain within the org" do
      post api_v1_detection_events_path, params: valid_params.merge(domain: "unknown.example.com"), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("unknown domain")
    end

    it "truncates page_title to 255 chars" do
      long_title = "A" * 300
      post api_v1_detection_events_path, params: valid_params.merge(page_title: long_title), as: :json

      event = DetectionEvent.last
      expect(event.page_title.length).to be <= 255
    end

    it "defaults detected_at to current time if unparseable" do
      post api_v1_detection_events_path, params: valid_params.merge(detected_at: "not-a-date"), as: :json

      expect(response).to have_http_status(:created)
      event = DetectionEvent.last
      expect(event.detected_at).to be_within(5.seconds).of(Time.current)
    end
  end
end
