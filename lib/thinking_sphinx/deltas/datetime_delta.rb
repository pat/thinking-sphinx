module ThinkingSphinx
  module Deltas
    class DatetimeDelta < ThinkingSphinx::Deltas::DefaultDelta
      attr_accessor :column, :threshold
      
      def initialize(index, options)
        @index      = index
        @column     = options.delete(:delta_column) || :updated_at
        @threshold  = options.delete(:threshold)    || 1.day
      end
      
      def index(model, instance = nil)
        # do nothing
      end
      
      def delayed_index(model)
        config = ThinkingSphinx::Configuration.instance
        
        output = [
          reindex(config, model),
          merge(config, model)
        ].join("\n")
        
        puts output unless ThinkingSphinx.suppress_delta_output?
      end
            
      def toggle(instance)
        # do nothing
      end
      
      def reset_query(model)
        nil
      end
      
      def clause(model, toggled)
        if toggled
          "#{model.quoted_table_name}.#{@index.quote_column(@column.to_s)}" +
          " > DATE_SUB(NOW(), INTERVAL #{@threshold} SECOND)"
        else
          nil
        end
      end
      
      private
      
      def reindex(config, model)
        `#{config.bin_path}indexer --config #{config.config_file} --rotate #{delta_index_name model}`
      end
      
      def merge(config, model)
        `#{config.bin_path}indexer --config #{config.config_file} --rotate --merge #{core_index_name model} #{delta_index_name model} --merge-dst-range sphinx_deleted 0 0`
      end
    end
  end
end
