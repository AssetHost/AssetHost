AssetHost::Application.routes.draw do  
  devise_for :users, :module => "admin"
  devise_for :api_users
  
  namespace :a, :module => "admin" do 
    
    resources :users
    
    resources :packages do
      resources :outputs
    end

    resources :assets, :id => /\d+/ do
      collection do 
        get :search
        post :upload
        get :metadata
        put :metadata, :action => "update_metadata"
      end

      member do
        get :preview
        post :replace
      end      
    end
    
    match '/assets/p/(:page)', :to => "assets#index", :as => "asset_page"
    
    match 'chooser', :to => "home#chooser", :as => 'chooser'
  end
  
  namespace :api do    
    resources :assets, :id => /\d+/ do
      member do
        get 'r/:context/(:scheme)', :action => :render
        get 'tag/:style', :action => :tag
      end
    end 

    match 'as_asset', :to => "utility#as_asset", :as => "as_asset"
  end
    
  match '/i/:aprint/:id-:style.:extension', :to => 'public#image', :as => :image, :constraints => { :id => /\d+/, :style => /[^\.]+/}
  
  match '/test', :to => "public#test"
  match '/slideshow', :to => "public#slideshow"
        
  root :to => 'public#index'
end