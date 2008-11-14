module Riddle
  class Configuration
    class DistributedIndex < Riddle::Configuration::Section
      self.settings = [:type, :local, :agent, :agent_connect_timeout,
        :agent_query_timeout]
      
      attr_accessor :name, :local_indexes, :remote_indexes,
        :agent_connect_timeout, :agent_query_timeout
      
      def initialize(name)
        @name           = name
        @local_indexes  = []
        @remote_indexes = []
      end
      
      def type
        "distributed"
      end
      
      def local
        self.local_indexes
      end
      
      def agent
        agents = remote_indexes.collect { |index| index.remote }.uniq
        agents.collect { |agent|
          agent + ":" + remote_indexes.select { |index|
            index.remote == agent
          }.collect { |index| index.name }.join(",")
        }
      end
      
      def render
        raise ConfigurationError unless valid?
        
        (
          ["index #{name}", "{"] +
          settings_body +
          ["}", ""]
        ).join("\n")
      end
      
      def valid?
        @local_indexes.length > 0 || @remote_indexes.length > 0
      end
    end
  end
end