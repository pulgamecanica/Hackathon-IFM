Rails.application.routes.draw do
  resources :users

  # Live feedback intelligence dashboard.
  get "dashboard" => "dashboard#index", as: :dashboard
  get "dashboard/map_data" => "dashboard#map_data", as: :map_data

  # Real-time ingestion API (stub feeder + real external sources POST here).
  namespace :api do
    namespace :v1 do
      post "feedbacks/ingest" => "feedbacks#create", as: :ingest_feedback
    end
  end
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
