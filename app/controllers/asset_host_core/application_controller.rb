module AssetHostCore
  class ApplicationController < ::ApplicationController
    helper_method :_current_user
    helper_method :_sign_out_path
    
    def _authenticate_user!
      instance_eval &AssetHostCore::Config.authentication_method
    end
    
    #----------
        
    def _current_user
      instance_eval &AssetHostCore::Config.current_user_method
    end
    
    #----------
    
    def _sign_out_path
      instance_eval &AssetHostCore::Config.sign_out_path
    end
    
    #----------
    
    def _authenticate_api_user!
      instance_eval &AssetHostCore::Config.api_authentication_method
    end
  end
end
