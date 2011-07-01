class Api::UtilityController < ApplicationController
  
  # Take a URL and try to find or create an asset out of it
  def as_asset
    if !params[:url]
      render :text => "Must provide an asset URL", :status => :bad_request
    end
    
    # see if we have a loader for this URL
    if asset = AssetHost.as_asset(url)

    else
      
    end
  end
end
