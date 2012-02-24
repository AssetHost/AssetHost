module AssetHostCore
  class Video < ActiveRecord::Base
    self.abstract_class = true

    has_one :asset
  end
end