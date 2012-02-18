module AssetHostCore
  class Engine < ::Rails::Engine
    isolate_namespace AssetHostCore

    config.assethost = ActiveSupport::OrderedOptions.new

  end
end
