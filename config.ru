# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

#log = File.new("log/rawupload.log", "a")
#STDOUT.reopen(log)
#STDERR.reopen(log)
use Rack::RawUpload, :paths => ['/a/assets/upload','/a/assets/*/replace']

run AssetHost::Application
