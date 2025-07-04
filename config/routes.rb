Rails.application.routes.draw do
  namespace :admin do
    resources :users, only: [ :index, :show, :edit, :update ] do
      member do
        patch :update_subscription
      end
    end
  end

  namespace :hub_admin do
    resource :configuration, only: [ :show, :update ]
  end
  devise_for :users

  get "pricing", to: "pricing#index", as: :pricing

  resources :sessions, only: [ :new, :create, :show, :destroy ]
  get "sign_in/:token", to: "sessions#show", as: :sign_in

  resources :dashboard, only: [ :index ]

  resources :subscriptions, only: [ :index, :new, :create ] do
    member do
      post :cancel
    end
  end

  namespace :checkout do
    get :success
    get :cancel
  end

  post "webhooks/stripe", to: "webhooks#stripe"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#index"
end
