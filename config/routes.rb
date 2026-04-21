Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post 'auth/login',    to: 'auth#login'
      post 'auth/register', to: 'auth#register'
      get  'auth/me',       to: 'auth#me'

      get   'users/me', to: 'users#me'
      patch 'users/me', to: 'users#update'
      get   'users/me/pending_invites', to: 'users#pending_invites'
      get   'users/:id', to: 'users#show'

      resources :events do
        member do
          get  :most_available_date
          post :resolve_tie
          post :confirm_winner
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
