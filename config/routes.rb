Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/login",           to: "auth#login"
      post "auth/register",        to: "auth#register"
      get  "auth/me",              to: "auth#me"
      post "auth/forgot_password", to: "auth#forgot_password"
      post "auth/reset_password",  to: "auth#reset_password"

      get   "users/me", to: "users#me"
      patch "users/me", to: "users#update"
      get   "users/me/pending_invites", to: "users#pending_invites"
      get   "users/me/contacts",        to: "users#contacts"
      get   "users/:id", to: "users#show"

      get  "events/invite_preview/:token", to: "events#invite_preview"
      post "events/join",                  to: "events#join_by_token"

      resources :events do
        member do
          get  :most_available_date
          post :resolve_tie
          post :confirm_winner
          post :confirm_time
        end
        resources :items,          only: [ :index, :create, :update, :destroy ]
        resources :invites,        only: [ :index, :create, :update, :destroy ]
        resources :availabilities, only: [ :create ]
        resources :votes,          only: [ :create ] do
          collection do
            get :tally
            get :time_tally
          end
        end
      end
    end
  end
end
