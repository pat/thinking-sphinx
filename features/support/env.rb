require 'rubygems'
require 'cucumber'
require 'spec'
require 'fileutils'
require 'ginger'
require 'will_paginate'
require 'active_record'

$:.unshift File.dirname(__FILE__) + '/../../lib'
Dir[File.join(File.dirname(__FILE__), '../../vendor/*/lib')].each do |path|
  $:.unshift path
end

require 'cucumber/thinking_sphinx/internal_world'

world = Cucumber::ThinkingSphinx::InternalWorld.new
world.configure_database

require "thinking_sphinx"

world.setup
