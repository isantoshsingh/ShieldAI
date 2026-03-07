module Admin
  class UsersController < BaseController
    def index
      @pagy, @users = pagy(:offset, User.includes(:organisation).order(created_at: :desc), limit: 25)
    end
  end
end
