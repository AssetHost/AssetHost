module AssetHost
  require "asset_host/paperclip.rb"
  require "asset_host/loaders.rb"
  
  Dir.glob("#{File.expand_path(File.join(File.dirname(__FILE__), 'asset_host/loaders'))}/*.rb").each {|imp| require imp }

  class << self
    # Pass url to our loader plugins and see if anyone bites.  Our first 
    # loader should always be the loader that handles our own API urls 
    # for existing assets.
    def as_asset(url)
      AssetHost::Loaders.load(url)
    end
    
    #----------
  end
end