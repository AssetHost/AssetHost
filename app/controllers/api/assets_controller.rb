class Api::AssetsController < ApplicationController
  
  before_filter :authenticate_user!

  def index
    if params[:q] && params[:q] != ''
      @assets = Asset.search(params[:q],
        :page => params[:page] =~ /^\d+$/ ? params[:page] : 1,
        :per_page => 24,
        :field_weights => { :title => 10, :caption => 3 }
      )
    else
      @assets = Asset.paginate(
        :order => "updated_at desc",
        :page => params[:page] =~ /^\d+$/ ? params[:page] : 1,
        :per_page => 24
      )
    end
    
    response.headers['X-Next-Page'] = @assets.next_page.to_s
    response.headers['X-Total-Entries'] = @assets.total_entries.to_s
    response.headers['Access-Control-Allow-Origin'] = "*"
    
    render :json => 
      @assets.collect { |a| { 
        :id => a.id, 
        :title => a.title, 
        :caption => a.caption,
        :owner => a.owner, 
        :size => [a.image_width,a.image_height].join('x'), 
        :tags => a.image.tags,
        :url => "http://#{ASSET_SERVER}/api/assets/#{a.id}/" 
      } }
  end
  
  #----------

  def show
    asset = Asset.find(params[:id])
    
    response.headers['Access-Control-Allow-Origin'] = "*"
    
    render :json => { 
      :id => asset.id, 
      :title => asset.title, 
      :caption => asset.caption, 
      :owner => asset.owner,
      :size => [asset.image_width,asset.image_height].join('x'),
      :tags => asset.image.tags
    }
  rescue
    render :text => "Asset not found", :status => :not_found
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
