require "thinking_sphinx"
require "resque"

module AssetHostCore
  class Engine < ::Rails::Engine
    @@mpath = nil
    @@redis_pubsub = nil
    
    isolate_namespace AssetHostCore

    # initialize our config hash
    config.assethost = ActiveSupport::OrderedOptions.new
    
    # -- configure resque -- #
    
    initializer :set_up_assethost_resque do 
      app_config = "#{Rails.application.root}/config/resque.yml"
            
      # use app resque config if it exists, otherwise supply our own
      resque_config = YAML.load_file(
        File.exists?(app_config) ? app_config : File.expand_path('../../../config/resque.yml',__FILE__)
      )
      Resque.redis = resque_config[Rails.env]
    end
    
    # -- post-initialization setup -- #

    config.after_initialize do
      # work around an issue where TS isn't seeing model directories if Rails hasn't appended the trailing slash
      ::ThinkingSphinx::Configuration.instance.model_directories << File.expand_path("../../../app/models",__FILE__) + "/"
      
      # set our resque job's queue
      AssetHostCore::ResqueJob.instance_variable_set :@queue, Rails.application.config.assethost.resque_queue      
    end
    
    # add resque's rake tasks
    rake_tasks do
      require "resque/tasks"
    end

    #----------
    
    def self.public_routes
      @@public_routes ||= ActionDispatch::Routing::RouteSet.new
    end
    
    #----------
    
    def self.mounted_path
      if @@mpath
        return @@mpath.spec.to_s == '/' ? '' : @@mpath.spec.to_s
      end
      
      # -- find our path -- #
      
      route = Rails.application.routes.routes.detect do |route|
        route.app == self
      end
        
      if route
        @@mpath = route.path
      end

      return @@mpath.spec.to_s == '/' ? '' : @@mpath.spec.to_s
    end
    
    #----------
    
    def self.redis_pubsub
      if Rails.application.config.assethost.redis_pubsub && Rails.application.config.assethost.redis_pubsub.is_a?(Hash)
        if @@redis_pubsub
          return @@redis_pubsub
        end
        
        return @@redis_pubsub ||= Redis.connect(:url => Rails.application.config.assethost.redis_pubsub[:server])
      else
        return false
      end
    end
    
    #----------
    
    def self.redis_publish(data)
      if r = self.redis_pubsub
        return r.publish(Rails.application.config.assethost.redis_pubsub[:key]||"AssetHost",data.to_json)
      else
        return false
      end
    end
  
    #----------
  
    class Public < ::Rails::Engine
    end
  end
end
