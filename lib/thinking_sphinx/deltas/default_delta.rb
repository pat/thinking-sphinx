module ThinkingSphinx
  module Deltas
    class DefaultDelta
      attr_accessor :column
      
      def initialize(index, options)
        @index  = index
        @column = options.delete(:column) || :delta
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
        ) if instance && instance.in_core_index?
        
        output = `#{config.bin_path}indexer --config #{config.config_file} --rotate #{delta_index_name model}`
        puts output unless ThinkingSphinx.suppress_delta_output?
        
        true
      end
      
      def toggle(instance)
        instance.delta = true
      end
      
      def clause(model, toggled)
        "#{model.quoted_table_name}.#{@index.quote_column(@column.to_s)}" +
        " = #{@index.db_boolean(toggled)}"
      end
      
      protected
      
      def core_index_name(model)
        "#{model.sphinx_indexes.first.name}_core"
      end
      
      def delta_index_name(model)
        "#{model.sphinx_indexes.first.name}_delta"
      end
    end
  end
end
