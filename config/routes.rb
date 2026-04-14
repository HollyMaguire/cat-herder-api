Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Auth
      post 'auth/login',    to: 'auth#login'
      post 'auth/register', to: 'auth#register'
      get  'auth/me',       to: 'auth#me'

      # Current user profile
      get   'users/me', to: 'users#me'
      patch 'users/me', to: 'users#update'
      get   'users/:id', to: 'users#show'

      # Events + nested resources
      resources :events do
        member do
          get  :most_available_date
          post :resolve_tie
        end
        resources :items,          only: [:index, :create, :update, :destroy]
        resources :invites,        only: [:index, :create, :update, :destroy]
        resources :availabilities, only: [:create]
        resources :votes,          only: [:create] do
          collection { get :tally }
        end
      end
    end
  end
end
