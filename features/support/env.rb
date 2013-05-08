require 'rubygems'
require 'fileutils'
require 'bundler'

Bundler.require :default, :development

$:.unshift File.dirname(__FILE__) + '/../../lib'

require 'active_record'
require 'cucumber/thinking_sphinx/internal_world'

world = Cucumber::ThinkingSphinx::InternalWorld.new
world.configure_database

require 'thinking_sphinx'

ActiveRecord::Base.send(:include, ThinkingSphinx::ActiveRecord)

ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural /^(.*)beta$/i, '\1betas'
  inflect.singular /^(.*)betas$/i, '\1beta'
end

world.setup
