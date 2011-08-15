class Admin::HomeController < ApplicationController
  before_filter :authenticate_user!

  #----------

  def chooser
    @assets = Asset.paginate(:per_page => 24, :page => 1, :order => "updated_at desc")
    
    render :layout => 'minimal'
  end
  
  #----------

end
