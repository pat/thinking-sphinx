require 'spec_helper'
require 'thinking_sphinx/railtie'

Combustion.initialize! :active_record

root = File.expand_path File.dirname(__FILE__)
Dir["#{root}/support/**/*.rb"].each { |file| require file }
