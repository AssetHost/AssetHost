AssetHost::Application.routes.draw do  
  devise_for :users, :module => "admin"
  
  namespace :a, :module => "admin" do 
    
    resources :users
    
    resources :packages

    resources :assets, :id => /\d+/ do
      collection do 
        get :search
        post :upload
        get :metadata
        put :metadata, :action => "update_metadata"
      end

      member do
        get :preview
      end
    end
  end
  
  namespace :api do    
    resources :assets, :id => /\d+/ do
      member do
        get 'tag/:style', :action => :tag
      end
    end 

    match 'as_asset', :to => "utility#as_asset", :as => "as_asset"
  end
    
  match '/i/:aprint/:id-:style.:extension', :to => 'public#image', :as => :image, :constraints => { :id => /\d+/, :style => /[^\.]+/}
  
  match '/test', :to => "public#test"
        
  root :to => 'public#index'
end