module Riddle
  class Configuration
    class DistributedIndex < Riddle::Configuration::Section
      def self.settings
        [
          :type, :local, :agent, :agent_blackhole,
          :agent_connect_timeout, :agent_query_timeout
        ]
      end

      attr_accessor :name, :local_indices, :remote_indices, :agent_blackhole,
        :agent_connect_timeout, :agent_query_timeout

      def initialize(name)
        @name             = name
        @local_indices    = []
        @remote_indices   = []
        @agent_blackhole  = []
      end

      def type
        "distributed"
      end

      def local
        self.local_indices
      end

      def agent
        agents = remote_indices.collect { |index| index.remote }.uniq
        agents.collect { |agent|
          agent + ":" + remote_indices.select { |index|
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
        @local_indices.length > 0 || @remote_indices.length > 0
      end
    end
  end
end
