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
        return true if instance && !toggled(instance)

        update_delta_indexes model
        delete_from_core     model, instance if instance

        true
      end

      def toggle(instance)
        instance.send "#{@column}=", true
      end

      def toggled(instance)
        instance.send "#{@column}"
      end

      def reset_query(model)
        "UPDATE #{model.quoted_table_name} SET " +
        "#{model.connection.quote_column_name(@column.to_s)} = #{adapter.boolean(false)} " +
        "WHERE #{model.connection.quote_column_name(@column.to_s)} = #{adapter.boolean(true)}"
      end

      def clause(model, toggled)
        "#{model.quoted_table_name}.#{model.connection.quote_column_name(@column.to_s)}" +
        " = #{adapter.boolean(toggled)}"
      end

      private

      def update_delta_indexes(model)
        ThinkingSphinx::Deltas::IndexJob.new(model.delta_index_names).perform
      end

      def delete_from_core(model, instance)
        ThinkingSphinx::Deltas::DeleteJob.new(
          model.core_index_names, instance.sphinx_document_id
        ).perform
      end

      def adapter
        @adapter = @index.model.sphinx_database_adapter
      end
    end
  end
end
