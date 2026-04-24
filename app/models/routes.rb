# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # ── Auth ────────────────────────────────────────────────────────────
      post "auth/login",    to: "auth#login"
      post "auth/register", to: "auth#register"
      get  "auth/me",       to: "auth#me"

      # ── Users ───────────────────────────────────────────────────────────
      get   "users/me",     to: "users#me"
      patch "users/me",     to: "users#update"
      get   "users/:id",    to: "users#show"

      # ── Events ──────────────────────────────────────────────────────────
      resources :events do
        member do
          get  :best_slots
          post :resolve_tie
        end

        resources :invites,        only: [ :index, :create, :update, :destroy ]
        resources :items,          only: [ :index, :create, :update, :destroy ]
        resources :availabilities, only: [ :create ]
        resources :votes,          only: [ :create ] do
          collection do
            get :tally
          end
        end
      end
    end
  end
end
