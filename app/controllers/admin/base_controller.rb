module Admin
  class BaseController < ApplicationController
    skip_before_action :authenticate_org_user!

    before_action :authenticate_super_admin!

    private

    def authenticate_super_admin!
      authenticate_user!
      unless current_user.super_admin?
        render plain: "Forbidden", status: :forbidden
      end
    end
  end
end
