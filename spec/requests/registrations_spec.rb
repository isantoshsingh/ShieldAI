require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "POST /signup" do
    let(:valid_params) do
      {
        organisation: { name: "Test Org" },
        user: {
          name: "Admin User",
          email: "admin@testorg.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    it "creates Organisation + User atomically" do
      expect {
        post signup_path, params: valid_params
      }.to change(Organisation, :count).by(1)
        .and change(User, :count).by(1)

      user = User.last
      expect(user.role).to eq("org_admin")
      expect(user.organisation).to eq(Organisation.last)
    end

    it "seeds ai_tools for the new org" do
      post signup_path, params: valid_params
      org = Organisation.last
      expect(org.ai_tools.count).to eq(35)
    end

    it "signs in the user and redirects to dashboard" do
      post signup_path, params: valid_params
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Dashboard")
    end

    it "does not create Organisation on user validation failure" do
      invalid_params = valid_params.deep_dup
      invalid_params[:user][:email] = ""

      expect {
        post signup_path, params: invalid_params
      }.to change(Organisation, :count).by(0)
        .and change(User, :count).by(0)
    end

    it "shows errors on validation failure" do
      invalid_params = valid_params.deep_dup
      invalid_params[:user][:email] = ""

      post signup_path, params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
