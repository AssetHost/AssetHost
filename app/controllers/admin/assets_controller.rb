class Admin::AssetsController < ApplicationController
  before_filter :authenticate_user!
  
  skip_before_filter :verify_authenticity_token, :only => [:upload, :replace]

  def index
    @assets = Asset.paginate(
      :order => "updated_at desc",
      :page => params[:page] =~ /^\d+$/ ? params[:page] : 1,
      :per_page => 24
    )
  end
  
  def search
    @assets = Asset.search params[:q], 
	    :page => params[:page] || 1, 
	    :per_page => 36,
	    :field_weights => {
	      :title => 10,
	      :description => 5
	    },
	    :order => "created_at DESC, @relevance DESC"
	    
	  
  end
  
  #----------
  
  def upload  
    file = params[:file]
            
    a = Asset.new(:title => file.original_filename.sub(/\.\w{3}$/,''))
    a.image = file
    
    if a.save
      render :text => a.id
    else
      puts "Error: #{a.errors.to_s}"
      render :text => 'ERROR'
    end
  end
  
  #----------
  
  def metadata
    @assets = Asset.find(params[:ids].split(','))
    
    # pre-fill with metadata from IPTC / EXIF
    @assets.each {|a|
      ([['title','image_title'],['description','image_description'],['owner','image_copyright']]).each {|f|
        if a[f[0]] == nil
          a[f[0]] = a[f[1]]
        end
      }
    }
  end
  
  #----------
  
  def update_metadata
    params[:asset].each {|k,v|
      a = Asset.find(k)
      a.update_attributes(v)
    }
    
    redirect_to a_assets_path
  end
  
  #----------
  
  def show
    @asset = Asset.find(params[:id])
  end
  
  #----------
  
  def preview
    @asset = Asset.find(params[:id])
    @output = Output.find_by_code(params[:output])
    
    render :update do |p|
      p.replace_html "preview", :partial => "preview"
    end
  end
  
  #----------
  
  def edit
    @asset = Asset.find(params[:id])
    
  end
  
  #----------
  
  def update
    @asset = Asset.find(params[:id])
    
    if @asset.update_attributes(params[:asset])
      flash[:notice] = "Successfully updated asset."
      redirect_to a_asset_path(@asset)
    else
      flash[:notice] = @asset.errors.full_messages.join("<br/>")
      render :action => :edit
    end
  end
  
  #----------
  
  def replace
    @asset = Asset.find(params[:id])
    
    if !params[:file]
      render :text => 'ERROR' and return
    end
    
    # tell paperclip to replace our image
    @asset.image = params[:file]
    
    if @asset.save
      render :text => @asset.id
    else
      puts "Error: #{@asset.errors.to_s}"
      render :text => 'ERROR'
    end
  end
  
  #----------
  
  def destroy
    
  end
end
