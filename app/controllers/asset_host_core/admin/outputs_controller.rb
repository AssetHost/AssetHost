module AssetHostCore
  class Admin::OutputsController < ApplicationController
  
    before_filter :load_output, :except => [:index,:new,:create]
  
    def index
    
    end
  
    #----------
  
    def show
    
    end
  
    #----------
  
    def edit
    
    end
  
    #----------
  
    def update
    
    end
  
    #----------
  
    def new
    
    end
  
    #----------
  
    def create
    
    end

    #----------
  
    private
    def load_output
      @output = @package.outputs.where(:id => params[:id]).first
    
      if !@output
        raise
      end
    rescue
      redirect_to a_package_path(@package)
    end
  end
end
