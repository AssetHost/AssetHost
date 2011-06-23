class Admin::AssetsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:upload]

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
        
    idkey = file.original_filename.sub(/\.\w{3}$/,'')
    
    a = Asset.new_with_unique_idkey(:idkey => idkey)
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
    params[:assets].each {|k,v|
      a = Asset.find(k)
      a.update_attributes(v)
    }
    
    redirect_to a_index_path
  end
  
  #----------
  
  def show
    @asset = Asset.find(params[:id])
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
      redirect_to a_path(@asset)
    else
      flash[:notice] = @asset.errors.full_messages.join("<br/>")
      render :action => :edit
    end
  end
  
  #----------
  
  def destroy
    
  end
end
