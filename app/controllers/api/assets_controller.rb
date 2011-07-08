class Api::AssetsController < ApplicationController

  def show
    asset = Asset.find(params[:id])
    
    render :json => { 
      :id => asset.id, 
      :title => asset.title, 
      :description => asset.description, 
      :owner => asset.owner,
      :tags => asset.image.tags
    }
  end
  
  #----------

  def tag
    # look up Asset
    asset = Asset.find(params[:id])
    
    # look up output style
    output = Output.where(:code => params[:style]).first
    
    # do we have a rendered AssetOutput?
    width = height = nil
    if ao = asset.outputs.where(:output_id => output).first
      width = ao.width
      height = ao.height
    end
        
    render :json => { 
      :id => asset.id, 
      :tag => asset.image.tag(params[:style].to_sym), 
      :updated_at => asset.image_updated_at, 
      :owner => asset.owner, 
      :width => width, 
      :height => height
    }
  end
  
  #----------
  
end
