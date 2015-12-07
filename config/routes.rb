# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
 resources :projects do
  resources :redmine_chart do
      post 'preview', :on => :collection
      put  'preview', :on => :member
  end
 end
 get 'redmine_chart', :to => 'redmine_chart#index'
end
