# frozen_string_literal: true

module ThinkingSphinx
  module ActiveRecord
    class SQLBuilder
      attr_reader :source

      def initialize(source)
        @source = source
      end

      def sql_query
        statement.to_relation.to_sql.gsub(/\n/, "\\\n")
      end

      def sql_query_range
        return nil if source.disable_range?
        statement.to_query_range_relation.to_sql
      end

      def sql_query_pre
        query.to_query
      end

      private

      delegate :adapter, :model, :delta_processor, :to => :source
      delegate :convert_nulls, :time_zone_query_pre, :utf8_query_pre,
        :cast_to_bigint, :to => :adapter

      def query
        Query.new(self)
      end

      def statement
        Statement.new(self)
      end

      def config
        ThinkingSphinx::Configuration.instance
      end

      def relation
        model.unscoped
      end

      def associations
        @associations ||= ThinkingSphinx::ActiveRecord::SourceJoins.call(
          model, source
        )
      end

      def quote_column(column)
        model.connection.quote_column_name(column)
      end

      def quoted_primary_key
        "#{model.quoted_table_name}.#{quote_column(source.primary_key)}"
      end

      def quoted_inheritance_column
        "#{model.quoted_table_name}.#{quote_column(model.inheritance_column)}"
      end

      def pre_select
        ('SQL_NO_CACHE ' if source.type == 'mysql').to_s
      end

      def big_document_ids?
        source.options[:big_document_ids] || config.settings['big_document_ids']
      end

      def document_id
        quoted_alias = quote_column source.primary_key
        column = quoted_primary_key
        column = cast_to_bigint column if big_document_ids?
        column = "#{column} * #{config.indices.count} + #{source.offset}"

        "#{column} AS #{quoted_alias}"
      end

      def range_condition
        condition = []
        condition << "#{quoted_primary_key} BETWEEN $start AND $end" unless source.disable_range?
        condition += source.conditions
        condition
      end

      def groupings
        groupings = source.groupings
        if model.column_names.include?(model.inheritance_column)
          groupings << quoted_inheritance_column
        end
        groupings
      end

      def model_name
        klass = model.name
        klass = klass.demodulize unless model.store_full_sti_class
        klass
      end
    end
  end
end

require 'thinking_sphinx/active_record/sql_builder/statement'
require 'thinking_sphinx/active_record/sql_builder/query'
