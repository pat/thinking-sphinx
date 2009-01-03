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
        true
      end
      
      def delayed_index(model)
        config = ThinkingSphinx::Configuration.instance
        
        output = `#{config.bin_path}indexer --config #{config.config_file} --rotate #{delta_index_name model}`
        puts output unless ThinkingSphinx.suppress_delta_output?
        
        true
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
    end
  end
end
