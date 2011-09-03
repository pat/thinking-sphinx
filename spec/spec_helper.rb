require 'rubygems'
require 'bundler'

Bundler.require :default, :development

root = File.expand_path File.dirname(__FILE__)
Dir["#{root}/support/**/*.rb"].each { |file| require file }

RSpec.configure do |config|
  sphinx = Sphinx.new

  config.before :all do |group|
    sphinx.setup && sphinx.start if group.class.metadata[:live]
  end

  config.after :all do |group|
    sphinx.stop if group.class.metadata[:live]
  end

  # enable filtering for examples
  config.filter_run :wip => nil
  config.run_all_when_everything_filtered = true
end
