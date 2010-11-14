require 'rubygems'
require 'fileutils'
require 'bundler'

Bundler.require :default, :development

$:.unshift File.dirname(__FILE__) + '/../../lib'
Dir[File.join(File.dirname(__FILE__), '../../vendor/*/lib')].each do |path|
  $:.unshift path
end

require 'active_record'
require 'cucumber/thinking_sphinx/internal_world'

world = Cucumber::ThinkingSphinx::InternalWorld.new
world.configure_database

require "thinking_sphinx"

ActiveRecord::Base.send(:include, ThinkingSphinx::ActiveRecord)

world.setup
