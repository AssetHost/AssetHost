class Admin::PackagesController < ApplicationController
  
  before_filter :authenticate_admin!
  
  def index
    @packages = SitePackage.all
  end
end
