$:.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'fileutils'
require 'ginger'
require 'not_a_mock'
require 'will_paginate'

require 'lib/thinking_sphinx'
require 'spec/sphinx_helper'

ActiveRecord::Base.logger = Logger.new(StringIO.new)

Spec::Runner.configure do |config|
  %w( tmp tmp/config tmp/log tmp/db ).each do |path|
    FileUtils.mkdir_p "#{Dir.pwd}/#{path}"
  end
  
  Kernel.const_set :RAILS_ROOT, "#{Dir.pwd}/tmp" unless defined?(RAILS_ROOT)
  
  sphinx = SphinxHelper.new
  sphinx.setup_mysql
  
  require 'spec/fixtures/models'
  
  config.before :all do
    %w( tmp tmp/config tmp/log tmp/db ).each do |path|
      FileUtils.mkdir_p "#{Dir.pwd}/#{path}"
    end
    
    @sphinx = sphinx
    
    ThinkingSphinx.updates_enabled = true
    ThinkingSphinx.deltas_enabled = true
    
    ThinkingSphinx::Configuration.instance.reset
    ThinkingSphinx::Configuration.instance.database_yml_file = "spec/fixtures/sphinx/database.yml"
    
    # Ensure after_commit plugin is loaded correctly
    Object.subclasses_of(ActiveRecord::ConnectionAdapters::AbstractAdapter).each { |klass|
      unless klass.ancestors.include?(AfterCommit::ConnectionAdapters)
        klass.send(:include, AfterCommit::ConnectionAdapters)
      end
    }
  end
  
  config.after :each do
    NotAMock::CallRecorder.instance.reset
    NotAMock::Stubber.instance.reset
  end
  
  config.after :all do
    FileUtils.rm_r "#{Dir.pwd}/tmp" rescue nil
  end
end
