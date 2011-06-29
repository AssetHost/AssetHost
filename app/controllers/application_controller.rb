class ApplicationController < ActionController::Base
  protect_from_forgery

  private
  def authenticate_admin!
    if !current_user || !current_user.is_admin?
      redirect_to admin_root_path
    else
      # ok
    end
  end
end
