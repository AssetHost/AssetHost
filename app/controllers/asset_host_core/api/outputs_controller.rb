module AssetHostCore
  class Api::OutputsController < ApplicationController
    before_filter :_authenticate_api_user!
  
    def index
      render :json => Output.all
    end
  
    #----------
  
    def show
      output = Output.find_by_code(params[:id])
    
      if output
        render :json => output
      else
        render :text => "Invalid output code", :status => :not_found
      end
    end
  end
end