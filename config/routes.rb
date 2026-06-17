Rails.application.routes.draw do
  resources :users

  # Live feedback intelligence dashboard.
  get "dashboard" => "dashboard#index", as: :dashboard
  get "dashboard/map_data" => "dashboard#map_data", as: :map_data

  # Feedback chatbot — natural-language querying with filters.
  post "chat" => "chat#create", as: :chat

  # LUMA Concierge — standalone, installable (PWA) mobile-first chat app.
  get "assistant" => "assistant#show", as: :assistant
  post "assistant" => "assistant#create"

  # AI chart generation — natural-language request → procedural chart.
  post "charts" => "charts#create", as: :charts

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

  # Dynamic PWA files (manifest + service worker) for the LUMA Concierge app.
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#index"
end

