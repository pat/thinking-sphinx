module ThinkingSphinx
  module Deltas
    class FlagAsDeletedJob
      attr_accessor :index, :document_id
      
      def initialize(index, document_id)
        @index, @document_id = index, document_id
      end
      
      def perform
        return true unless ThinkingSphinx.updates_enabled?
        
        config = ThinkingSphinx::Configuration.instance
        client = Riddle::Client.new config.address, config.port
        
        client.update(
          @index,
          ['sphinx_deleted'],
          {@document_id => [1]}
        ) if ThinkingSphinx.sphinx_running? &&
          ThinkingSphinx::Search.search_for_id(@document_id, @index)
        
        true
      end
    end
  end
end