$:.unshift File.dirname(__FILE__) + '/../lib'
Dir[File.join(File.dirname(__FILE__), '../vendor/*/lib')].each do |path|
  $:.unshift path
end

require 'rubygems'
require 'fileutils'
require 'bundler'

Bundler.require :default, :development

require "#{File.dirname(__FILE__)}/../lib/thinking_sphinx"
require "#{File.dirname(__FILE__)}/sphinx_helper"

ActiveRecord::Base.logger = Logger.new(StringIO.new)

RSpec.configure do |config|
  %w( tmp tmp/config tmp/log tmp/db ).each do |path|
    FileUtils.mkdir_p "#{Dir.pwd}/#{path}"
  end

  Kernel.const_set :RAILS_ROOT, "#{Dir.pwd}/tmp" unless defined?(RAILS_ROOT)

  sphinx = SphinxHelper.new
  sphinx.setup_mysql

  require "#{File.dirname(__FILE__)}/fixtures/models"
  ThinkingSphinx.context.define_indexes

  config.before :each do
    %w( tmp tmp/config tmp/log tmp/db ).each do |path|
      FileUtils.mkdir_p "#{Dir.pwd}/#{path}"
    end

    ThinkingSphinx.updates_enabled = true
    ThinkingSphinx.deltas_enabled = true
    ThinkingSphinx.suppress_delta_output = true

    ThinkingSphinx::Configuration.instance.reset
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
        'sphinx_internal_id'    => instance.id,
        'sphinx_internal_class' => instance.class.name,
        'class_crc'             => instance.class.name.to_crc32
      }
    }
  end
end
