# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  get  '/health_check', to: 'health_checks#index'
  get  '/blogs',        to: 'blogs#index'
  get  '/blogs/:id',    to: 'blogs#show'
  post '/blogs',        to: 'blogs#create'
end
