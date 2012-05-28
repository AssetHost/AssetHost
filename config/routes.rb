AssetHostCore::Engine.routes.draw do
  namespace :a, :module => "admin" do 
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

    resources :outputs

    resources :brightcove

    match '/assets/search', :to => "assets#search", :as => "asset_search"
    match '/assets/p/:page/:q', :to => "assets#search"
    match '/assets/p/(:page)', :to => "assets#index", :as => "asset_page"

    match 'chooser', :to => "home#chooser", :as => 'chooser'
    
    root :to => "home#index"
  end

  namespace :api do    
    resources :assets, :id => /\d+/ do
      member do
        get 'r/:context/(:scheme)', :action => :render
        get 'tag/:style', :action => :tag
      end
    end 
    
    resources :outputs

    match 'as_asset', :to => "utility#as_asset", :as => "as_asset"    
  end
  
  root :to => "public#home"
end

AssetHostCore::Engine::Public.routes.draw do
  match '/:aprint/:id-:style.:extension', :to => 'public#image', :as => :image, :constraints => { :id => /\d+/, :style => /[^\.]+/}
end
