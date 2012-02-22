require "thinking_sphinx"

module AssetHostCore
  class Engine < ::Rails::Engine
    isolate_namespace AssetHostCore

    config.assethost = ActiveSupport::OrderedOptions.new

    config.after_initialize do
      #puts "adding model dir at #{ File.expand_path("../../../app/models/",__FILE__) }"
      ::ThinkingSphinx::Configuration.instance.model_directories << File.expand_path("../../../app/models",__FILE__) + "/"
      AssetHostCore::ResqueJob.instance_variable_set :@queue, Rails.application.config.assethost.resque_queue      
    end
  end
end
