Rails.application.routes.draw do

  root 'static_pages#index'

  get 'static_pages/about'

  get 'static_pages/faq'

  get 'static_pages/contact'

  devise_for :users, :controllers => { :registrations => 'registrations', :omniauth_callbacks => "callbacks"}

  get '/users/auth/:provider/callback', to: 'sessions#create'
  post '/auth/:provider/callback' => 'authentications#create'


end
