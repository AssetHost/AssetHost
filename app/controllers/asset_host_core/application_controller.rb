module AssetHostCore
  class ApplicationController < ActionController::Base
    helper_method :current_user
    helper_method :sign_out_path
    
    def authenticate_user!
      instance_eval &AssetHostCore::Config.authentication_method
    end
    
    #----------
        
    def current_user
      instance_eval &AssetHostCore::Config.current_user_method
    end
    
    #----------
    
    def sign_out_path
      instance_eval &AssetHostCore::Config.sign_out_path
    end
    
    #----------
    
    def authenticate_api_user!
      instance_eval &AssetHostCore::Config.api_authentication_method
    end
  end
end
