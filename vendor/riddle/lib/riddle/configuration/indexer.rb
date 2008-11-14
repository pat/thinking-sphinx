module Riddle
  class Configuration
    class Indexer < Riddle::Configuration::Section
      self.settings = [:mem_limit, :max_iops, :max_iosize]
      
      attr_accessor *self.settings
            
      def render
        raise ConfigurationError unless valid?
        
        (
          ["indexer", "{"] +
          settings_body +
          ["}", ""]
        ).join("\n")
      end
    end
  end
end