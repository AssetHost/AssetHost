plugin_test = File.dirname(__FILE__)
plugin_root = File.join plugin_test, '..'
plugin_lib = File.join plugin_root, 'lib'

require 'rubygems'
require 'active_support'
require 'active_record'
require 'test/spec'
require 'logger'
require 'mocha'

$:.unshift plugin_lib, plugin_test

module Rails
  mattr_accessor :env, :root, :logger
end

Rails.env = "test"
Rails.root = File.dirname(__FILE__) + "/.." # fake the rails root directory.
Rails.logger = Logger.new(STDOUT)
Rails.logger.level = Logger::WARN

require "mocks/spawn"
require "mocks/logger"
require "workling"
require "workling/base"

Workling.try_load_a_memcache_client

require "workling/discovery"
require "workling/routing/class_and_method_routing"
require "workling/remote/invokers/basic_poller"
require "workling/remote/invokers/threaded_poller"
require "workling/remote/invokers/eventmachine_subscriber"
require "workling/remote"
require "workling/remote/runners/not_remote_runner"
require "workling/remote/runners/spawn_runner"
require "workling/remote/runners/starling_runner"
require "workling/remote/runners/client_runner"
require "workling/remote/runners/backgroundjob_runner"
require "workling/return/store/memory_return_store"
require "workling/return/store/starling_return_store"
require "mocks/client"
require "clients/memory_queue_client"
require "runners/thread_runner"

# worklings are in here.
Workling.load_path = ["#{ plugin_root }/test/workers"]
Workling::Return::Store.instance = Workling::Return::Store::MemoryReturnStore.new
Workling::Discovery.discover!

# make this behave like production code
Workling.raise_exceptions = false