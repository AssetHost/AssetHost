require "paperclip"
require File.join(File.dirname(__FILE__), "lib", "image_asset")

if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, ImageAsset)
end