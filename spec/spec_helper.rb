require 'rubygems'
require 'bundler'

Bundler.require :default, :development

require 'thinking_sphinx/railtie'

Combustion.initialize! :active_record

if ENV['SPHINX_VERSION'].try :[], /2.1.\d/
  ThinkingSphinx::SphinxQL.functions!
end

root = File.expand_path File.dirname(__FILE__)
Dir["#{root}/support/**/*.rb"].each { |file| require file }

RSpec.configure do |config|
  # enable filtering for examples
  config.filter_run :wip => nil
  config.run_all_when_everything_filtered = true
end
