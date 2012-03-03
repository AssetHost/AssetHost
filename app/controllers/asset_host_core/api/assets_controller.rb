module AssetHostCore
  class Api::AssetsController < ApplicationController
  
    before_filter :_authenticate_api_user!

    def index
      if params[:q] && params[:q] != ''
        @assets = Asset.visible.search(params[:q],
          :page => params[:page] =~ /^\d+$/ ? params[:page] : 1,
          :per_page => 24,
          :field_weights => { :title => 10, :caption => 3 },
          :order => "created_at DESC, @relevance DESC"
        )
      else
        @assets = Asset.visible.paginate(
          :order => "updated_at desc",
          :page => params[:page] =~ /^\d+$/ ? params[:page] : 1,
          :per_page => 24
        )
      end
    
      response.headers['X-Next-Page'] = @assets.next_page.to_s
      response.headers['X-Total-Entries'] = @assets.total_entries.to_s
      response.headers['Access-Control-Allow-Origin'] = "*"
    
      render :json => @assets.collect { |a| a.json }
    end
  
    #----------

    def show
      asset = Asset.find(params[:id])
    
      response.headers['Access-Control-Allow-Origin'] = "*"
    
      render :json => asset.json
    rescue
      render :text => "Asset not found", :status => :not_found
    end
  
    #----------
  
    def update
      asset = Asset.find(params[:id])

      response.headers['Access-Control-Allow-Origin'] = "*"

      if asset.update_attributes(params[:asset])
        render :json => asset.json
      else
        render :text => asset.errors.full_messages.join(" | "), :status => :error
      end
    end
  
    #----------

    def tag
      begin
        # look up Asset
        asset = Asset.find(params[:id])
      rescue
        render :text => "Asset not found", :status => :not_found and return
      end
    
      # look up output style
      output = Output.where(:code => params[:style]).first
    
      # do we have a rendered AssetOutput?
      width = height = nil
      if ao = asset.outputs.where(:output_id => output).first
        width = ao.width
        height = ao.height
      end
    
      response.headers['Access-Control-Allow-Origin'] = "*"
        
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
end