require "asset_host_core/engine"

require "paperclip"

require "asset_host_core/paperclip"
require "asset_host_core/loaders"
require "asset_host_core/config"

Dir.glob("#{File.expand_path(File.join(File.dirname(__FILE__), 'asset_host_core/loaders'))}/*.rb").each {|imp| require imp }

module AssetHostCore
  class << self
    # Pass url to our loader plugins and see if anyone bites.  Our first 
    # loader should always be the loader that handles our own API urls 
    # for existing assets.
    def as_asset(url)
      AssetHostCore::Loaders.load(url)
    end
  end
  
  def self.hooks(&block)
    block.call(AssetHostCore::Config)
  end
end

if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, AssetHostCore::Paperclip)
end