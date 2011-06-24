module ApplicationHelper
  def render_asset(asset,code)
    output = Output.find_by_code(code)
    
    if output.is_rich?
      # try template for native type, default to photo
      begin
        raise Exception
      rescue Exception
        begin
          render :partial => "shared/assets/photo/#{code}", :object => asset, :as => :asset, :locals => { :output => output }        
        rescue
          render :partial => "shared/assets/photo/default", :object => asset, :as => :asset, :locals => { :output => output }        
        end        
      end
    else
      # render photo output
      begin
        render :partial => "shared/assets/photo/#{code}", :object => asset, :as => :asset, :locals => { :output => output }        
      rescue
        render :partial => "shared/assets/photo/default", :object => asset, :as => :asset, :locals => { :output => output }        
      end
    end
  end
end
