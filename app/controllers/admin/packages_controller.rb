class Admin::PackagesController < ApplicationController
  
  before_filter :authenticate_admin!
  
  def index
    @packages = SitePackage.all
  end
  
  def show
    @package = SitePackage.find(params[:id])
    @asset = Asset.find(params[:asset]||:first)
  end
end
