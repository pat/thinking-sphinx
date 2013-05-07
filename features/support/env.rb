require 'rubygems'
require 'fileutils'
require 'bundler'

Bundler.require :default, :development

$:.unshift File.dirname(__FILE__) + '/../../lib'

require 'cucumber/thinking_sphinx/internal_world'

world = Cucumber::ThinkingSphinx::InternalWorld.new
world.configure_database

require "thinking_sphinx"

world.setup
