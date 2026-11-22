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

  # 使い方の画面（#115）。ログインしていなくても読める
  get "guide", to: "static_pages#guide", as: :guide

  # ユーザー登録（S2）
  resources :users, only: %i[new create]

  # ログイン（S3）・ログアウト
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout
  # 「お試しで見る」：登録なしで見本の曼荼羅を見る（見るだけ）
  post "demo", to: "demo_sessions#create", as: :demo_session

  # ログイン後のHome（曼荼羅）
  get "home", to: "home#index", as: :home

  # わたしの轍（真ん中の丸から開く毎日の日誌）。日付で開く（例：/diaries/2026-11-17）
  resources :diaries, only: %i[index show update], param: :date
  # △ できなかった予定を、明日の轍へ写す（#123）
  post "diary_plans/:id/carry", to: "diary_plans#carry", as: :carry_diary_plan

  # 大窓（局面）の画面と、名前の編集（#13）
  resources :phases, only: %i[show edit update] do
    # 小窓（窓 1〜8）の作成（#14）・詳細（#16）・編集（#17）・削除（#18）
    resources :windows, only: %i[new create show edit update destroy], shallow: true do
      # 課題の作成（#19）・編集（#21）・削除（#22）・「済み」と「まだに戻す」（#23）
      resources :plans, only: %i[create edit update destroy] do
        member do
          patch :done
          patch :undone
        end
      end
      # 記録の作成（#24）・編集（#26）・削除（#27）
      resources :entries, only: %i[create edit update destroy]
    end
  end
end
