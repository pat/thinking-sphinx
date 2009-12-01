require 'riddle/configuration/section'

require 'riddle/configuration/distributed_index'
require 'riddle/configuration/index'
require 'riddle/configuration/indexer'
require 'riddle/configuration/remote_index'
require 'riddle/configuration/searchd'
require 'riddle/configuration/source'
require 'riddle/configuration/sql_source'
require 'riddle/configuration/xml_source'

module Riddle
  class Configuration
    class ConfigurationError < StandardError #:nodoc:
    end
    
    attr_reader :indexes, :searchd
    attr_accessor :indexer
    
    def initialize
      Riddle.version_warning
      
      @indexer = Riddle::Configuration::Indexer.new
      @searchd = Riddle::Configuration::Searchd.new
      @indexes = []
    end
    
    def render
      (
        [@indexer.render, @searchd.render] +
        @indexes.collect { |index| index.render }
      ).join("\n")
    end
  end
end
