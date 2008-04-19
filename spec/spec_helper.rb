$:.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'fileutils'
require 'not_a_mock'

require 'lib/thinking_sphinx'
require 'spec/sphinx_helper'

Spec::Runner.configure do |config|
  # config.mock_with NotAMock::RspecMockFrameworkAdapter
  
  sphinx = SphinxHelper.new
  sphinx.setup_mysql
  
  config.before :all do
    %w( tmp tmp/config tmp/log tmp/db ).each do |path|
      FileUtils.mkdir_p "#{Dir.pwd}/#{path}"
    end
    
    Kernel.const_set :RAILS_ROOT, "#{Dir.pwd}/tmp" unless defined?(RAILS_ROOT)
    
    # sphinx.start
  end
  
  config.after :all do
    # sphinx.stop
    
    FileUtils.rm_r "#{Dir.pwd}/tmp"
  end
end