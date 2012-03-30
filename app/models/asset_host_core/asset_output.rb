module AssetHostCore
  class AssetOutput < ActiveRecord::Base
    belongs_to :asset
    belongs_to :output
    
    before_save :delete_cache_and_img, :if => Proc.new { |ao| ao.fingerprint_changed? || ao.image_fingerprint_changed? }
    before_destroy :delete_cache_and_img
    
    after_save :cache_img_path, :if => Proc.new { |ao| ao.image_fingerprint? && ao.fingerprint? }

    scope :rendered, where("fingerprint != ''")
    
    #----------
        
    protected
    
    # on save, check whether we should be creating or deleting caches
    def delete_cache_and_img
      # -- out with the old -- #
      
      finger    = self.fingerprint_changed? ? self.fingerprint_was : self.fingerprint
      imgfinger = self.image_fingerprint_changed? ? self.image_fingerprint_was : self.image_fingerprint
      
      if finger && imgfinger
        # -- delete our old cache -- #
        Rails.cache.delete("img:"+[self.id,imgfinger,self.output.code].join(":"))
        
        # -- delete our AssetOutput -- #
        path = self.asset.image.path(self.output.code_sym)
        if path
          # this path could have our current values in it. make sure we've 
          # got old fingerprints
          path = path.gsub(self.asset.image_fingerprint,imgfinger).gsub(self.fingerprint,finger)

          Rails.logger.debug("Deleting AssetOutput image at #{path}")
          self.asset.image.delete_path(path)
        end
      end
    end
    
    #----------
    
    def cache_img_path
      # -- in with the new -- #
      path = self.asset.image.path(self.output.code_sym)
      
      if path
        Rails.cache.write("img:"+[self.id,self.image_fingerprint,self.output.code].join(":"),path)
      end
    end
  end
end
