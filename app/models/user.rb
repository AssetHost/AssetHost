class User < ActiveRecord::Base
  devise :database_authenticatable, :token_authenticatable, :rememberable

  belongs_to :default_site, :class_name => "SitePackage"
  
  attr_accessible :email, :password, :password_confirmation, :remember_me, :username
end
