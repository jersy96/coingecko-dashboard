Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "market_feed/assets#index"

  get "sign_in" => "authorization/sign_in#show"

  get "asset_catalog" => "market_feed/asset_catalog#index"

  resources :watchlist_items, only: [ :index, :create, :destroy ], controller: "market_feed/watchlist_items"

  resources :thresholds, only: [ :index, :update ], controller: "market_feed/thresholds"

  resources :activity_entries, only: [ :index ], controller: "auditing/activity_entries"

  resource :access_token, only: [ :create ], controller: "authorization/access_tokens"
end
