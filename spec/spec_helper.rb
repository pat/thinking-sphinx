$:.unshift File.dirname(__FILE__) + '/../lib'
Dir[File.join(File.dirname(__FILE__), '../vendor/*/lib')].each do |path|
  $:.unshift path
end

require 'rubygems'
require 'fileutils'
require 'ginger'
require 'jeweler'
require "rspec"

require "lib/thinking_sphinx"

require 'will_paginate'

require 'spec/sphinx_helper'

ActiveRecord::Base.logger = Logger.new(StringIO.new)

Rspec.configure do |config|
  %w( tmp tmp/config tmp/log tmp/db ).each do |path|
    FileUtils.mkdir_p "#{Dir.pwd}/#{path}"
  end
  
  module ::Rails
    def self.root
      "#{Dir.pwd}/tmp"
    end
  end
  
  sphinx = SphinxHelper.new
  sphinx.setup_mysql
  
  require 'spec/fixtures/models'
  ThinkingSphinx.context.define_indexes
  
  config.before :all do
    %w( tmp tmp/config tmp/log tmp/db ).each do |path|
      FileUtils.mkdir_p "#{Dir.pwd}/#{path}"
    end
    
    ThinkingSphinx.updates_enabled = true
    ThinkingSphinx.deltas_enabled = true
    ThinkingSphinx.suppress_delta_output = true
    
    ThinkingSphinx::Configuration.instance.reset
    ThinkingSphinx::Configuration.instance.database_yml_file = "spec/fixtures/sphinx/database.yml"

    ActiveRecord::Base.send(:include, ThinkingSphinx::ActiveRecord)
  end
  
  config.after :all do
    FileUtils.rm_r "#{Dir.pwd}/tmp" rescue nil
  end
end

def minimal_result_hashes(*instances)
  instances.collect do |instance|
    {
      :weight     => 21,
      :attributes => {
        'sphinx_internal_id' => instance.id,
        'class_crc'          => instance.class.name.to_crc32
      }
    }
  end
end
