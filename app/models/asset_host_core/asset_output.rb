module AssetHostCore
  class AssetOutput < ActiveRecord::Base
    belongs_to :asset
    belongs_to :output
    
    before_save :delete_cache, :if => Proc.new { |ao| ao.fingerprint_changed? || ao.image_fingerprint_changed? }
    before_destroy :delete_cache

    scope :rendered, where("fingerprint != ''")
    
    #----------
        
    protected
    def delete_cache
      # -- find fingerprints -- #
      
      # if we previously didn't have a fingerprint, nothing to delete
      if self.fingerprint_changed? && !self.fingerprint_was
        return true
      end

      finger    = self.fingerprint_changed? ? self.fingerprint_was : self.fingerprint
      imgfinger = self.image_fingerprint_changed? ? self.image_fingerprint_was : self.image_fingerprint
      
      if finger && imgfinger
        # -- delete AssetOutput image -- #

        path = self.asset.image.path(self.output.code_sym)
        puts "gsub #{self.asset.image_fingerprint} -> #{imgfinger}"
        puts "ao imgfinger #{self.image_fingerprint_changed?} ? #{self.image_fingerprint_was} : #{self.image_fingerprint}"
        path.gsub!(self.asset.image_fingerprint,imgfinger)
      
        Rails.logger.debug("Deleting AssetOutput image at #{path}")
        self.asset.image.delete_path(path)
      
        # -- delete cached path -- #
      
        Rails.cache.delete("img:"+[imgfinger,self.output.code].join(":"))
      end
    end
  end
end
