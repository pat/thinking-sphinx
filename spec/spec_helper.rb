# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'logger'

Bundler.require :default, :development

root = File.expand_path File.dirname(__FILE__)
require "#{root}/support/multi_schema"
require "#{root}/support/json_column"
require "#{root}/support/mysql"
require 'thinking_sphinx/railtie'

Combustion.initialize! :active_record

MultiSchema.new.create 'thinking_sphinx'

require "#{root}/support/sphinx_yaml_helpers"

RSpec.configure do |config|
  # enable filtering for examples
  config.filter_run :wip => nil
  config.run_all_when_everything_filtered = true

  config.around :each, :live do |example|
    example.run_with_retry :retry => 3
  end
end
