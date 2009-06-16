module ThinkingSphinx
  module Deltas
    class DeltaJob
      attr_accessor :index
      
      def initialize(index)
        @index = index
      end
      
      def perform
        return true unless ThinkingSphinx.updates_enabled? &&
          ThinkingSphinx.deltas_enabled?
        
        config = ThinkingSphinx::Configuration.instance
        client = Riddle::Client.new config.address, config.port
        
        output = `#{config.bin_path}#{config.indexer_binary_name} --config #{config.config_file} --rotate #{index}`
        puts output unless ThinkingSphinx.suppress_delta_output?
        
        true
      end
    end
  end
end
