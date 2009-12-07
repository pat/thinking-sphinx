require 'rubygems'
require 'cucumber'
require 'spec'
require 'fileutils'
require 'ginger'
require 'dm-core'
require 'active_record'
require 'will_paginate'

$:.unshift File.dirname(__FILE__) + '/../../lib'
Dir[File.join(File.dirname(__FILE__), '../../vendor/*/lib')].each do |path|
  $:.unshift path
end

require 'cucumber/thinking_sphinx/internal_world'

world = Cucumber::ThinkingSphinx::InternalWorld.new
world.configure_database

require "thinking_sphinx"

world.setup
