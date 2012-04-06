module AssetHostCore
  class PublicController < AssetHostCore::ApplicationController
    
    def home
      render :text => "", :status => :ok, :layout => false
    end
    
    #----------
  
    # Given a fingerprint, id and style, determine whether the size has been cut. 
    # If so, redirect to the image file. If not, fire off a render process for 
    # the style.
    def image
      # if we have a cache key with aprint and style, assume we're good 
      # to just return that value
      if img = Rails.cache.read("img:#{params[:id]}:#{params[:aprint]}:#{params[:style]}")
        send_file img, :type => "image/jpeg", :disposition => 'inline' and return
      end
    
      @asset = Asset.where(:id => params[:id]).first
    
      # valid id?
      if !@asset
        render :text => "Asset not found.", :status => :not_found and return
      end
    
      # valid style?
      style = Output.where(:code => params[:style]).first
      if !style
        render :text => "Invalid style (#{params[:style]}).", :status => :not_found and return
      end
    
      # do the fingerprints match? If not, redirect them to the correct URL
      if @asset.image_fingerprint && params[:aprint] != @asset.image_fingerprint
        redirect_to image_path(:aprint => @asset.image_fingerprint, :id => @asset.id, :style => params[:style]), :status => :moved_permanently and return
      end
    
      # do we have a rendered output for this style?
      ao = @asset.outputs.where(:output_id => style)
    
      if ao.first
        if ao.first.fingerprint
          # Yes, return the image
                          
          # the file may still not have been written yet. loop a try to return it
        
          (0..5).each do 
            if @asset.image.exists? style.code_sym
              # got it.  cache and return
              
              path = @asset.image.path(style.code)
              Rails.logger.debug("PublicController cache_img_path for #{@asset.id}/#{style.code_sym} got #{path}")
              Rails.cache.write("img:#{@asset.id}:#{@asset.image_fingerprint}:#{style.code}",path)
              
              send_file path, :type => "image/jpeg", :disposition => 'inline' and return
            end
          
            # nope... sleep!
            sleep 0.5
          end
        
          # crap.  totally failed.
          redirect_to @asset.image.url(style.code) and return
        else
          # we're in the middle of rendering
          # sleep for 500ms to try and let the render complete, then try again
          sleep 0.5
          redirect_to @asset.image.url(style.code) and return
        end
      
      else
        # No, fire a render for the style
      
        # create an AssetOutput with no fingerprint
        @asset.outputs.create(:output_id => style.id, :image_fingerprint => @asset.image_fingerprint)
      
        # and fire the queue  
        @asset.image.enqueue_styles(style.code)
      
        # now, sleep for 500ms to try and let the render complete, then try again
        sleep 0.5
        redirect_to @asset.image.url(style.code) and return
      end    
    end
  
    #----------  
  end
  
  #----------

end
