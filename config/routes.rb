AssetHost::Application.routes.draw do
  #devise_for :a
  
  resources :a, :controller => "admin/assets", :id => /\d+/ do
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
      
  root :to => 'public#index'
end