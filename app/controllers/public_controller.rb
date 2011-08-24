class PublicController < ApplicationController
  
  # Given a fingerprint, id and style, determine whether the size has been cut. 
  # If so, redirect to the image file. If not, fire off a render process for 
  # the style.
  def image
    # if we have a cache key with aprint and style, assume we're good 
    # to just return that value
    if img = read_fragment("img:"+[params[:aprint],params[:style]].join(":"))
      send_file img, :type => "image/jpeg", :disposition => 'inline' and return
      #redirect_to img, status => :found and return
    end
    
    @asset = Asset.where(:id => params[:id]).first
    
    # valid id?
    if !@asset
      render :text => "Asset not found.", :status => :not_found and return
    end
    
    # valid style?
    style = Output.where(:code => params[:style])
    if !style.first
      render :text => "Invalid style (#{params[:style]}).", :status => :not_found and return
    end
    
    # do the fingerprints match? If not, redirect them to the correct URL
    if @asset.image_fingerprint && params[:aprint] != @asset.image_fingerprint
      redirect_to image_path(:aprint => @asset.image_fingerprint, :id => @asset.id, :style => params[:style]), :status => :moved_permanently and return
    end
    
    # do we have a rendered output for this style?
    ao = @asset.outputs.where(:output_id => style.first)
    
    if ao.first
      if ao.first.fingerprint
        # Yes, return a temporary redirect to the true image URL
        path = @asset.image.path(style.first.code)
        
        #url = @asset.image.trueurl(style.first.code)
        write_fragment("img:"+[@asset.image_fingerprint,style.first.code].join(":"), path)
        send_file path, :type => "image/jpeg", :disposition => 'inline' and return
        
        #redirect_to url, :status => :found and return        
      else
        # we're in the middle of rendering
        # sleep for 500ms to try and let the render complete, then try again
        sleep 0.5
        redirect_to @asset.image.url(style.first.code) and return
        
      end
      
    else
      # No, fire a render for the style
      
      # create an AssetOutput with no fingerprint
      @asset.outputs.create(:output_id => style.first.id)
      
      # and fire the queue  
      @asset.image.enqueue_styles(style.first.code)
      
      # now, sleep for 500ms to try and let the render complete, then try again
      sleep 0.5
      redirect_to @asset.image.url(style.first.code) and return
    end    
  end
  
  #----------
  
  def test
    render :layout => "preauth"
  end
end
