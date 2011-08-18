class AssetObserver < ActionController::Caching::Sweeper  
  observe :asset
  
  def after_save(record)
    @controller ||= ActionController::Base.new
    record = (record.class == Asset) ? record : record.asset
    
    Paperclip.log("[ewr] removing caches for asset at #{record.image_fingerprint} on #{cache_store}")
    
    # remove caches
    #cache_store.delete_matched("views/img:#{record.image_fingerprint}:*")
  end
end
