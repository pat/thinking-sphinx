require 'rubygems'
require 'cucumber'
require 'spec'
require 'fileutils'
require 'ginger'
require 'will_paginate'
require 'active_record'

$:.unshift File.dirname(__FILE__) + '/../../lib'

require 'cucumber/thinking_sphinx/internal_world'

world = Cucumber::ThinkingSphinx::InternalWorld.new
world.configure_database

SphinxVersion = ENV['VERSION'] || '0.9.8'
require "thinking_sphinx/#{SphinxVersion}"

world.setup
