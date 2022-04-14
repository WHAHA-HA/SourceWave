require 'sidekiq/pro/web'

Rails.application.routes.draw do

  # root 'home#index'
  # root 'plans#index'
  root 'sales#index'
  get 'sales', to: 'sales#index', as: 'sales'
  get 'home', to: 'home#index', as: 'home'
  get :dashboard, to: 'dashboard#index'

  get 'terms', to: 'home#terms', as: 'terms'
  get 'earnings_disclaimer', to: 'home#earnings_disclaimer', as: 'earnings_disclaimer'
  get 'general_disclaimer', to: 'home#general_disclaimer', as: 'general_disclaimer'

  get 'domains/:id' => "sites#index", as: :domains
  get 'copy_to_clipboard' => 'application#copy_to_clipboard', as: :copy_to_clipboard

  # Landing Pages
  get 'lp/marketplace', to: 'lp#marketplace', as: 'marketplace_lp'

  # Paypal Accounts
  resource :paypal_accounts

  # Subscriptions
  get 'new_basic_subscription', to: 'subscriptions#new_basic', as: 'new_basic_subscription'
  post 'create_basic_subscription', to: 'subscriptions#create_basic', as: 'create_basic_subscription'
  resource :subscriptions
  get 'create_trial_for_existing_customer' => 'subscriptions#create_trial_for_existing_customer', as: :create_trial_for_existing_customer
  get 'reactivate' => 'subscriptions#reactivate', as: :reactivate
  resources :trial_subscriptions
  get 'upgrade_subscription', to:'subscriptions#upgrade_subscription', as: 'upgrade_subscription'
  post 'subscriptions/cancel_webhook', to: 'subscriptions#cancel_webhook', as: 'cancel_webhook'
  post 'subscriptions/charge_failure_webhook', to: 'subscriptions#charge_failure_webhook', as: 'charge_failure_webhook'
  post 'upgrade_subscription_with_card', to: 'subscriptions#upgrade_subscription_with_card', as: 'upgrade_subscription_with_card'
  get 'upgrade_card_details', to: 'subscriptions#upgrade_card_details', as: 'upgrade_card_details'

  resources :pages
  resources :plans
  get 'secret_squirrel' => 'plans#secret_squirrel', as: 'secret_squirrel'
  get 'plans-v2' => 'plans#plansv2', as: 'plansv2'
  get 'upgrade_plan', to: 'plans#upgrade_plan'

  # Users
  resources :users
  resources :sessions
  resources :password_resets
  get 'signup', to: 'users#new', as: 'signup'
  get 'login', to: 'sessions#new', as: 'login'
  get 'logout', to: 'sessions#destroy', as: 'logout'
  get :account, to: 'users#account'

  # Sites

  resources :sites do
    collection do
      put 'sites/:id/save_bookmarked' => "sites#save_bookmarked", as: :save_bookmarked
      put 'sites/:id/unbookmark' => "sites#unbookmark", as: :unbookmark
      get ':id/bookmarked' => "sites#bookmarked", as: :bookmarked
      get 'delete', as: :delete
    end
  end
  get 'sites/:id/urls' => "sites#all_urls", as: :all_urls
  get 'sites/:id/internal' => "sites#internal", as: :internal
  get 'sites/:id/external' => "sites#external", as: :external
  get 'sites/:id/broken' => "sites#broken", as: :broken
  get 'sites/:id/available' => "sites#available", as: :available
  get 'sites/:crawl_id/anchor_texts' => 'sites#anchor_texts', as: :anchor_texts

  # Crawls
  resources :crawls
  get 'projects/' => "crawls#index", as: :projects
  get 'running_crawls' => "crawls#running", as: :running_crawls
  get 'finished_crawls' => "crawls#finished", as: :finished_crawls
  get 'projects/new' => "crawls#new", as: :new_project
  get 'projects/:id' => "crawls#show", as: :crawl_path
  get 'stop_crawl/:id' => 'crawls#stop_crawl', as: :stop_crawl
  post 'shut_down_crawl' => 'crawls#shut_down_crawl', as: :shut_down_crawl
  get 'crawls/keyword/new' => 'crawls#new_keyword_crawl', as: :new_keyword_crawl
  post 'crawls/keyword/create' => 'crawls#create_keyword_crawl', as: :create_keyword_crawl
  get 'crawls/reverse/new' => 'crawls#new_reverse_crawl', as: :new_reverse_crawl
  post 'crawls/reverse/create' => 'crawls#create_reverse_crawl', as: :create_reverse_crawl
  post 'api_create', to: 'crawls#api_create'
  post 'fetch_new_crawl', to: 'crawls#fetch_new_crawl'
  post 'call_crawl', to: 'crawls#call_crawl'
  post 'migrate_db', to: 'crawls#migrate_db'
  post 'process_new_crawl', to: 'crawls#process_new_crawl'
  get 'start_crawl', to: 'crawls#start_crawl', as: :start_crawl
  get 'delete_crawl/:id', to: 'crawls#delete_crawl', as: :delete_crawl

  resources :pending_crawls do
    collection {post :sort}
  end

  # Marketplace
  resources :domains_for_sale
  get 'domains_sold', to: 'domains_for_sale#sold', as: 'domains_sold'
  get 'domains_purchased', to: 'domains_for_sale#purchased', as: 'domains_purchased'
  resources :marketplace
  resources :domains_cart
  get 'domains_thank_you', to: 'domains_cart#thank_you', as: 'domains_thank_you'
  post "add_domain_to_cart/:id", to: 'domains_cart#add_domain_to_cart', as: "add_domain_to_cart"
  post 'leave_review', to: 'domains_cart#leave_review', as: 'leave_review'
  get 'verify_domain', to: 'domains_cart#verify_domain', as: 'verify_domain'

  # Admin
  resources :admins do
    collection do
      get :become_user
      get :edit_user
      put :update_user
      put :maintenance
      post :create_user
      get :new_user
      get :make_user_active
      get :make_user_inactive
    end
  end

  mount Sidekiq::Web, at: '/sidekiq'

  # get '*path' => redirect('/dashboard')

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
