module Super
  class BaseController < ApplicationController
    skip_before_action :authenticate_org_user!

    before_action :require_super_admin!

    private

    def require_super_admin!
      authenticate_user!
      unless current_user.super_admin?
        render plain: "Forbidden", status: :forbidden
      end
    end
  end
end
