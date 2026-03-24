Rails.application.routes.draw do
  # Devise: sign in + sign out only
  devise_for :users, skip: [:registrations, :passwords, :confirmations]

  # Public self-signup (unauthenticated)
  get  "/signup", to: "registrations#new",    as: :signup
  post "/signup", to: "registrations#create"

  # Org-scoped dashboard (org_admin + org_member)
  root "dashboard#index"

  resources :employees, only: [:index, :show, :new, :create, :destroy] do
    member { get :more_events }
    member { patch :regenerate_token }
  end

  resources :ai_tools, only: [:index, :create] do
    member { patch :toggle_approved }
  end

  resources :reports, only: [:index] do
    collection { post :export }
  end

  # Super admin namespace (super_admin only)
  namespace :super do
    root "dashboard#index"
    resources :organisations, only: [:index, :show, :new, :create]
    resources :users, only: [:index]
  end

  # Chrome extension API (no session auth, token-based)
  namespace :api do
    namespace :v1 do
      resources :detection_events, only: [:create]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
