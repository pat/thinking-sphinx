require 'rubygems'
require 'cucumber'
require 'spec'
require 'fileutils'
require 'ginger'
require 'will_paginate'
require 'yaml'
require 'active_record'
require 'active_record/connection_adapters/mysql_adapter'
require 'active_record/connection_adapters/postgresql_adapter' rescue nil

$:.unshift File.dirname(__FILE__) + '/../../lib'

require 'lib/thinking_sphinx'

ThinkingSphinx.suppress_delta_output = true

%w( tmp/config tmp/log tmp/db/sphinx/development ).each do |path|
  FileUtils.mkdir_p "#{Dir.pwd}/#{path}"
end

Kernel.const_set :RAILS_ROOT, "#{Dir.pwd}/tmp" unless defined?(RAILS_ROOT)

require 'features/fixtures/setup'

at_exit do
  ThinkingSphinx::Configuration.instance.controller.stop
  sleep(1) # Ensure Sphinx has shut down completely
  FileUtils.rm_r "#{Dir.pwd}/tmp"
end