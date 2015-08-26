SixDegreesOfKevinBacon::Application.routes.draw do
  
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  
  resources :movies do
    collection do
      get 'relations'
    end
  end
  
  resources :people
  
  root 'movies#index'
  
end
