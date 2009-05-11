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
        rotate = ThinkingSphinx.sphinx_running? ? "--rotate" : ""
        
        output = `#{config.bin_path}indexer --config #{config.config_file} #{rotate} #{delta_index_name model}`
        output += `#{config.bin_path}indexer --config #{config.config_file} #{rotate} --merge #{core_index_name model} #{delta_index_name model} --merge-dst-range sphinx_deleted 0 0`
        puts output unless ThinkingSphinx.suppress_delta_output?
        
        true
      end
            
      def toggle(instance)
        # do nothing
      end
      
      def toggled(instance)
        instance.send(@column) > @threshold.ago
      end
      
      def reset_query(model)
        nil
      end
      
      def clause(model, toggled)
        if toggled
          "#{model.quoted_table_name}.#{model.connection.quote_column_name(@column.to_s)}" +
          " > #{adapter.time_difference(@threshold)}"
        else
          nil
        end
      end
    end
  end
end
