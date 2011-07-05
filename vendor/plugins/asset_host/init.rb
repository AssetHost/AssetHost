require "paperclip"
require File.join(File.dirname(__FILE__), "lib", "asset_host")

if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, AssetHost::Paperclip)
end