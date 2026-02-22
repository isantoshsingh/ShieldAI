Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "users/activate"
      post "events"
      get  "users/me"
    end
  end

  root "dashboard#index"
  resources :users, only: [:index, :show]
  resources :tools, only: [:index]

  get  "auth/login",          to: "auth#login",      as: :login
  post "auth/send_link",      to: "auth#send_link"
  get  "auth/magic/:token",   to: "auth#magic_login", as: :magic_login
  delete "auth/logout",       to: "auth#logout",     as: :logout
end
