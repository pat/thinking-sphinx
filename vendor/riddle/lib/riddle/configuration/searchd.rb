module Riddle
  class Configuration
    class Searchd < Riddle::Configuration::Section
      self.settings = [:address, :port, :log, :query_log, :read_timeout,
        :max_children, :pid_file, :max_matches, :seamless_rotate,
        :preopen_indexes, :unlink_old]
      
      attr_accessor *self.settings
            
      def render
        raise ConfigurationError unless valid?
        
        (
          ["searchd", "{"] +
          settings_body +
          ["}", ""]
        ).join("\n")
      end
      
      def valid?
        !( @port.nil? || @pid_file.nil? )
      end
    end
  end
end