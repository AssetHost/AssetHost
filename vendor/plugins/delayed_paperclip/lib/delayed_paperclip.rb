require 'paperclip'

require 'delayed/paperclip'
require 'delayed/jobs/resque_paperclip_job'
require 'delayed/jobs/delayed_paperclip_job'
require 'delayed/workers/paperclip_worker'

if defined? Workling
  # this should only trigger for the workling listener
  Workling.load_path << File.dirname(__FILE__) + "/../lib/delayed/workers/"
end

if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, Delayed::Paperclip)
end