module ThinkingSphinx
  module Deltas
    class DefaultDelta
      attr_accessor :column
      
      def initialize(index, options)
        @index  = index
        @column = options.delete(:delta_column) || :delta
      end
      
      def index(model, instance = nil)
        return true unless ThinkingSphinx.updates_enabled? &&
          ThinkingSphinx.deltas_enabled?
        
        config = ThinkingSphinx::Configuration.instance
        client = Riddle::Client.new config.address, config.port
        
        client.update(
          core_index_name(model),
          ['sphinx_deleted'],
          {instance.sphinx_document_id => [1]}
        ) if instance && ThinkingSphinx.sphinx_running? && instance.in_core_index?
        
        output = `#{config.bin_path}indexer --config #{config.config_file} --rotate #{delta_index_name model}`
        puts output unless ThinkingSphinx.suppress_delta_output?
        
        true
      end
      
      def toggle(instance)
        instance.delta = true
      end
      
      def toggled(instance)
        instance.delta
      end
      
      def reset_query(model)
        "UPDATE #{model.quoted_table_name} SET " +
        "#{@index.quote_column(@column.to_s)} = #{adapter.boolean(false)}"
      end
      
      def clause(model, toggled)
        "#{model.quoted_table_name}.#{@index.quote_column(@column.to_s)}" +
        " = #{adapter.boolean(toggled)}"
      end
      
      protected
      
      def core_index_name(model)
        "#{model.source_of_sphinx_index.name.underscore.tr(':/\\', '_')}_core"
      end
      
      def delta_index_name(model)
        "#{model.source_of_sphinx_index.name.underscore.tr(':/\\', '_')}_delta"
      end  
      
      private
      
      def adapter
        @adapter = @index.model.sphinx_database_adapter
      end
    end
  end
end
