module AssetHostCore
  class Admin::AssetsController < ApplicationController
    before_filter :_authenticate_user!
    
    before_filter :load_asset, :only => [:show,:update,:replace,:destroy]
    
    skip_before_filter :verify_authenticity_token, :only => [:upload, :replace]

    #----------

    def index
      @assets = Asset.visible.paginate(
        :order => "updated_at desc",
        :page => params[:page] =~ /^\d+$/ ? params[:page] : 1,
        :per_page => 24
      )
    end

    #----------

    def search
      @assets = Asset.visible.search params[:q], 
  	    :page => params[:page] || 1, 
  	    :per_page => 24,
  	    :field_weights => {
  	      :title => 10,
  	      :caption => 5
  	    },
  	    :order => "created_at DESC, @relevance DESC"

  	  @query = params[:q]

  	  render :action => :index
    end

    #----------

    def upload  
      file = params[:file]

      # FIXME: Put in place to keep Firefox 7 happy
      if !file.original_filename
        file.original_filename = "upload.jpg"
      end

      asset = nil
      Asset.transaction do
        asset = Asset.create(:title => file.original_filename.sub(/\.\w{3}$/,''))
        asset.image = file

        # force _grab_dimensions to run early so that we can load in EXIF
        asset.image._grab_dimensions()

        [
          ['title','image_title'],
          ['caption','image_description'],
          ['owner','image_copyright']
        ].each {|f| asset[f[0]] = asset[f[1]] }        
      end


      if asset.save
        render :json => asset.json
      else
        puts "Error: #{asset.errors.to_s}"
        render :text => 'ERROR'
      end
    end

    #----------

    def metadata
      @assets = Asset.where(:id => params[:ids].split(','))
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
    end

    #----------

    def update
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
      if !params[:file]
        render :text => 'ERROR' and return
      end

      puts "file is #{params[:file]}"

      # tell paperclip to replace our image
      @asset.image = params[:file]

      # force _grab_dimensions to run early so that we can load in EXIF
      @asset.image._grab_dimensions()

      [
        ['title','image_title'],
        ['caption','image_description'],
        ['owner','image_copyright']
      ].each {|f| @asset[f[0]] = @asset[f[1]] }

      if @asset.save
        render :json => @asset.json
      else
        puts "Error: #{@asset.errors.to_s}"
        render :text => 'ERROR'
      end
    end

    #----------

    def destroy
      if @asset.destroy
        flash[:notice] = "Deleted asset #{@asset.title}."
        redirect_to a_assets_path
      else
        flash[:error] = "Unable to delete asset."
        redirect_to a_asset_path(@asset)
      end
    end
    
    #----------
    
    protected
    
    def load_asset
      @asset = Asset.find(params[:id])
    rescue
      redirect_to a_assets_path
    end
  end
end