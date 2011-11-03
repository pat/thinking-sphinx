module Riddle
  class Configuration
    class RealtimeIndex < Riddle::Configuration::Section
      def self.settings
        [
          :type, :path, :rt_mem_limit, :rt_field, :rt_attr_uint,
          :rt_attr_bigint, :rt_attr_float, :rt_attr_timestamp, :rt_attr_string
        ]
      end
      
      attr_accessor :name
      attr_accessor *self.settings
      
      def initialize(name)
        @name               = name
        @rt_field           = []
        @rt_attr_uint       = []
        @rt_attr_bigint     = []
        @rt_attr_float      = []
        @rt_attr_timestamp  = []
        @rt_attr_string     = []
      end
      
      def type
        "rt"
      end
      
      def valid?
        !(@name.nil? || @path.nil?)
      end
      
      def render
        raise ConfigurationError unless valid?
        
        (
          ["index #{name}", "{"] +
          settings_body +
          ["}", ""]
        ).join("\n")
      end
    end
  end
end
