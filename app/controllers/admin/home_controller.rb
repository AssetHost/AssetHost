class Admin::HomeController < ApplicationController
  before_filter :authenticate_user!

  #----------

  def chooser
    render :layout => 'minimal'
  end
  
  #----------

end
