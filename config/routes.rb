AssetHost::Application.routes.draw do
  #devise_for :a
  
  resources :a, :controller => "admin/assets" do
    collection do 
      get :search
      post :upload
      get :metadata
      post :update_metadata
    end
  end
      
  root :to => 'public#index'
end