class AssetOutputObserver < ActionController::Caching::Sweeper  
  observe :asset_output
  
  def before_destroy(ao)
    @controller ||= ActionController::Base.new
    
    Paperclip.log("[ewr] removing caches for AssetOutput at #{ao.image_fingerprint} on #{cache_store}")
    
    # remove cache
    expire_fragment("img:#{ao.image_fingerprint}:#{ao.output.code}")
    
    # delete file
    path = ao.asset.image.path(ao.output.code)
    path.gsub(ao.asset.image_fingerprint,ao.image_fingerprint)

    Paperclip.log("[EWR] Deleting old thumbnail at #{path}")
    ao.asset.image.delete_style(path)
    
    true
  end
end
