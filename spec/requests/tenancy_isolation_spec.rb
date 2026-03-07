require "rails_helper"

RSpec.describe "Tenancy Isolation", type: :request do
  let(:org_a) { create(:organisation) }
  let(:org_b) { create(:organisation) }
  let(:admin_a) { create(:user, :org_admin, organisation: org_a) }
  let(:admin_b) { create(:user, :org_admin, organisation: org_b) }
  let(:employee_a) { create(:employee, organisation: org_a) }
  let(:employee_b) { create(:employee, organisation: org_b) }

  describe "Employees" do
    it "Org A admin cannot access Org B employee (returns 404)" do
      sign_in admin_a
      get employee_path(employee_b)
      expect(response).to have_http_status(:not_found)
    end

    it "Org A admin can access own employees" do
      sign_in admin_a
      get employee_path(employee_a)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "AI Tools" do
    it "PATCH toggle_approved for Org B-only tool returns 404" do
      sign_in admin_a
      # Create a tool that only Org B has in its join table
      unique_tool = create(:ai_tool, domain: "orgb-only.example.com")
      create(:organisation_ai_tool, organisation: org_b, ai_tool: unique_tool, approved: false)
      patch toggle_approved_ai_tool_path(unique_tool)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Detection Events on Dashboard" do
    it "Dashboard stat cards for Org A do not include Org B events" do
      tool_a = org_a.ai_tools.first
      tool_b = org_b.ai_tools.first

      # Create events for both orgs
      3.times do
        create(:detection_event, organisation: org_a, employee: employee_a, ai_tool: tool_a)
      end
      5.times do
        create(:detection_event, organisation: org_b, employee: employee_b, ai_tool: tool_b)
      end

      sign_in admin_a
      get root_path

      # Check stat card contains "3" for Total Sessions (Org A only)
      doc = Nokogiri::HTML(response.body)
      total_sessions_card = doc.at_css("#stat-total-sessions")
      expect(total_sessions_card.text).to include("3")
      expect(total_sessions_card.text).not_to include("8")
    end
  end

  describe "Super admin routing" do
    let(:super_admin) { create(:user, :super_admin) }

    it "super_admin hitting GET / receives 403" do
      sign_in super_admin
      get root_path
      expect(response).to have_http_status(:forbidden)
    end

    it "super_admin can access GET /super" do
      sign_in super_admin
      get super_root_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "org_admin vs org_member" do
    let(:member_a) { create(:user, :org_member, organisation: org_a) }

    it "org_member gets 403 on employees#create" do
      sign_in member_a
      post employees_path, params: { employee: { name: "Test", email: "test@example.com" } }
      expect(response).to have_http_status(:forbidden)
    end

    it "org_member gets 403 on employees#destroy" do
      sign_in member_a
      delete employee_path(employee_a)
      expect(response).to have_http_status(:forbidden)
    end

    it "org_member gets 403 on ai_tools#toggle_approved" do
      sign_in member_a
      tool_a = org_a.ai_tools.first
      patch toggle_approved_ai_tool_path(tool_a)
      expect(response).to have_http_status(:forbidden)
    end

    it "org_admin succeeds on employees#create" do
      sign_in admin_a
      post employees_path, params: { employee: { name: "New Employee", email: "new@example.com" } }
      expect(response).to have_http_status(:redirect)
    end

    it "org_admin succeeds on ai_tools#toggle_approved" do
      sign_in admin_a
      tool_a = org_a.ai_tools.first
      patch toggle_approved_ai_tool_path(tool_a)
      expect(response).to have_http_status(:redirect)
    end

    it "org_member gets 403 on reports#export" do
      sign_in member_a
      post export_reports_path, params: { start_date: 30.days.ago.to_date, end_date: Date.today }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "Employee#risk_level" do
    it "returns 'low' for 0 unapproved events" do
      expect(employee_a.risk_level).to eq("low")
    end

    it "returns 'medium' for 1-2 unapproved events" do
      unapproved_tool = create(:ai_tool)
      create(:organisation_ai_tool, organisation: org_a, ai_tool: unapproved_tool, approved: false)
      create(:detection_event, organisation: org_a, employee: employee_a, ai_tool: unapproved_tool)
      expect(employee_a.risk_level).to eq("medium")
    end

    it "returns 'high' for 3+ unapproved events" do
      unapproved_tool = create(:ai_tool)
      create(:organisation_ai_tool, organisation: org_a, ai_tool: unapproved_tool, approved: false)
      3.times { create(:detection_event, organisation: org_a, employee: employee_a, ai_tool: unapproved_tool) }
      expect(employee_a.risk_level).to eq("high")
    end

    it "approved tool events do not count" do
      approved_tool = create(:ai_tool)
      create(:organisation_ai_tool, organisation: org_a, ai_tool: approved_tool, approved: true)
      5.times { create(:detection_event, organisation: org_a, employee: employee_a, ai_tool: approved_tool) }
      expect(employee_a.risk_level).to eq("low")
    end

    it "events from other orgs do not count" do
      unapproved_tool_b = create(:ai_tool)
      create(:organisation_ai_tool, organisation: org_b, ai_tool: unapproved_tool_b, approved: false)
      5.times { create(:detection_event, organisation: org_b, employee: employee_b, ai_tool: unapproved_tool_b) }
      expect(employee_a.risk_level).to eq("low")
    end
  end
end
