module AssetHostCore
  class Admin::OutputsController < AssetHostCore::ApplicationController
  
    before_filter :load_output, :except => [:index,:new,:create]
  
    def index
      @outputs = Output.all
    end
  
    #----------
  
    def show
    
    end
  
    #----------
  
    def edit
    
    end
  
    #----------
  
    def update
      if @output.update_attributes params[:output]
        flash[:notice] = "Output updated!"
        redirect_to a_output_path @output
      else
        flash[:error] = "Failed to create output: #{@output.errors}"
        render :action => :edit
      end
    end
  
    #----------
  
    def new
      @output = Output.new
    end
  
    #----------
  
    def create
      @output = Output.new
      
      if @output.update_attributes params[:output]
        flash[:notice] = "Output created!"
        redirect_to a_output_path @output
      else
        flash[:error] = "Failed to create output: #{@output.errors}"
        render :action => :new
      end
    end
    
    #----------
    
    def destroy
      
    end

    #----------
  
    private
    def load_output
      @output = Output.where(:id => params[:id]).first
    
      if !@output
        raise
      end
    rescue
      redirect_to a_package_path(@package)
    end
  end
end
