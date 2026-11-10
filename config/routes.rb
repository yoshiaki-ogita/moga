Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "static_pages#top"

  # ユーザー登録（S2）
  resources :users, only: %i[new create]

  # ログイン（S3）・ログアウト
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # ログイン後のHome（曼荼羅）
  get "home", to: "home#index", as: :home

  # 大窓（局面）の画面と、名前の編集（#13）
  resources :phases, only: %i[show edit update] do
    # 小窓（窓 1〜8）の作成（#14）・詳細（#16）・編集（#17）・削除（#18）
    resources :windows, only: %i[new create show edit update destroy], shallow: true
  end
end
