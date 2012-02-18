class Admin::SessionsController < Devise::SessionsController
  layout "preauth"
end
