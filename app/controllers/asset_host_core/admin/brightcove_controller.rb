module AssetHostCore
  class Admin::BrightcoveController < ApplicationController
    before_filter :authenticate_user!
  
    def index
      @assets = AssetHostCore::Asset.visible.where(:native_type => 'AssetHostCore::BrightcoveVideo').paginate(
        :order => "updated_at desc",
        :page => params[:page] =~ /^\d+$/ ? params[:page] : 1,
        :per_page => 24
      )
    
    end
  
    def create
      bimport = AssetHostCore::Loaders::Brightcove.new(params[:videoid])
    
      @asset = bimport.load()
    
      if @asset
        redirect_to a_asset_path(@asset)
      else
        flash[:notice] = "Unable to import video.  Invalid ID?"
        redirect_to a_brightcove_index_path()
      end
    end
  end
end