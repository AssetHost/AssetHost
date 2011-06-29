class AssetOutput < ActiveRecord::Base
  belongs_to :asset
  belongs_to :output
  
  scope :rendered, where("fingerprint != ''")
end
