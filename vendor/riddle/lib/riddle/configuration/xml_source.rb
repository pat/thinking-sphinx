module Riddle
  class Configuration
    class XMLSource < Riddle::Configuration::Source
      def self.settings 
        [
          :type, :xmlpipe_command, :xmlpipe_field,
          :xmlpipe_attr_uint, :xmlpipe_attr_bool, :xmlpipe_attr_timestamp,
          :xmlpipe_attr_str2ordinal, :xmlpipe_attr_float, :xmlpipe_attr_multi,
          :xmlpipe_fixup_utf8
        ]
      end
      
      attr_accessor *self.settings
      
      def initialize(name, type)
        @name = name
        @type = type
        
        @xmlpipe_field            = []
        @xmlpipe_attr_uint        = []
        @xmlpipe_attr_bool        = []
        @xmlpipe_attr_timestamp   = []
        @xmlpipe_attr_str2ordinal = []
        @xmlpipe_attr_float       = []
        @xmlpipe_attr_multi       = []
      end
            
      def valid?
        super && ( !@xmlpipe_command.nil? || !parent.nil? )
      end
    end
  end
end
