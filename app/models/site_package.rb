class SitePackage < ActiveRecord::Base
  has_many :outputs
  
  validates :name, :uniqueness => true, :presence => true
  
  #----------
end
