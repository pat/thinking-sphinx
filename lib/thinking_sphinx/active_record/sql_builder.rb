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

      def sql_query_info
        statement.to_query_info_relation.to_sql
      end

      def sql_query_pre
        query.to_query
      end

      private

      def query
        Query.new(self)
      end

      def statement
        Statement.new(self)
      end

      def config
        ThinkingSphinx::Configuration.instance
      end

      delegate :adapter, :model, :delta_processor, :to => :source
      delegate :convert_nulls, :utf8_query_pre, :to => :adapter
      def relation
        model.unscoped
      end

      def base_join
        @base_join ||= join_dependency_class.new model, [], initial_joins
      end

      def associations
        @associations ||= ThinkingSphinx::ActiveRecord::Associations.new(model).tap do |assocs|
          source.associations.reject(&:string?).each do |association|
            assocs.add_join_to association.stack
          end
        end
      end

      def custom_joins
        @custom_joins ||= source.associations.select(&:string?).collect(&:to_s)
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

      def document_id
        quoted_alias = quote_column source.primary_key
        "#{quoted_primary_key} * #{config.indices.count} + #{source.offset} AS #{quoted_alias}"
      end

      def reversed_document_id
        "($id - #{source.offset}) / #{config.indices.count}"
      end

      def attribute_presenters
        @attribute_presenters ||= property_sql_presenters_for(source.attributes)
      end

      def field_presenters
        @field_presenters ||= property_sql_presenters_for(source.fields)
      end

      def property_sql_presenters_for(fields)
        fields.collect { |field| property_sql_presenter_for(field) }
      end

      def property_sql_presenter_for(field)
        ThinkingSphinx::ActiveRecord::PropertySQLPresenter.new(
          field, source.adapter, associations
        )
      end

      def select_clause
        ClauseBuilder.new(document_id).compose(
          presenters_to_select(field_presenters),
          presenters_to_select(attribute_presenters)
        ).separated
      end

      def where_clause(for_range = false)
        builder = ClauseBuilder.new(nil)
        builder.add_clause inheritance_column_condition unless model.descends_from_active_record?
        builder.add_clause delta_processor.clause(source.delta?) if delta_processor
        builder.add_clause range_condition unless for_range
        builder.separated(' AND ')
      end

      def inheritance_column_condition
        "#{quoted_inheritance_column} = '#{model_name}'"
      end

      def range_condition
        condition = []
        condition << "#{quoted_primary_key} BETWEEN $start AND $end" unless source.disable_range?
        condition += source.conditions
        condition
      end

      def group_clause
        ClauseBuilder.new(quoted_primary_key).compose(
          presenters_to_group(field_presenters),
          presenters_to_group(attribute_presenters),
          groupings
        ).separated
      end

      def presenters_to_group(presenters)
        presenters.collect(&:to_group)
      end

      def presenters_to_select(presenters)
        presenters.collect(&:to_select)
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

require 'thinking_sphinx/active_record/sql_builder/clause_builder'
require 'thinking_sphinx/active_record/sql_builder/statement'
require 'thinking_sphinx/active_record/sql_builder/query'
