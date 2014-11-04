require 'thinking_sphinx/active_record/sql_builder/clause_builder'

module ThinkingSphinx
  module ActiveRecord
    class SQLBuilder::Statement
      def initialize(report)
        @report = report
        @scope  = relation
      end

      def to_relation
        filter_by_scopes

        scope
      end

      def to_query_range_relation
        filter_by_query_range

        scope
      end

      def to_query_info_relation
        filter_by_query_info

        scope
      end

      def to_query_pre
        filter_by_query_pre

        scope
      end

      private

      attr_reader :report, :scope

      def custom_joins
        @custom_joins ||= source.associations.select(&:string?).collect(&:to_s)
      end

      def filter_by_query_range
        minimum = convert_nulls "MIN(#{quoted_primary_key})", 1
        maximum = convert_nulls "MAX(#{quoted_primary_key})", 1

        @scope = scope.select("#{minimum}, #{maximum}").where(
          where_clause(true)
        )
      end

      def filter_by_query_info
        @scope = scope.where("#{quoted_primary_key} = #{reversed_document_id}")
      end

      def filter_by_scopes
        scope_by_select
        scope_by_where_clause
        scope_by_group_clause
        scope_by_joins
        scope_by_custom_joins
        scope_by_order
      end

      def attribute_presenters
        @attribute_presenters ||= property_sql_presenters_for source.attributes
      end

      def field_presenters
        @field_presenters ||= property_sql_presenters_for source.fields
      end

      def presenters_to_group(presenters)
        presenters.collect(&:to_group)
      end

      def presenters_to_select(presenters)
        presenters.collect(&:to_select)
      end

      def property_sql_presenters_for(properties)
        properties.collect { |property| property_sql_presenter_for(property) }
      end

      def property_sql_presenter_for(property)
        ThinkingSphinx::ActiveRecord::PropertySQLPresenter.new(
          property, source.adapter, associations
        )
      end

      def scope_by_select
        @scope = scope.select(pre_select + select_clause)
      end

      def scope_by_where_clause
        @scope = scope.where where_clause
      end

      def scope_by_group_clause
        @scope = scope.group(group_clause)
      end

      def scope_by_joins
        @scope = scope.joins(associations.join_values)
      end

      def scope_by_custom_joins
        @scope = scope.joins(custom_joins) if custom_joins.any?
      end

      def scope_by_order
        @scope = scope.order('NULL') if source.type == 'mysql'
      end

      def source
        report.source
      end

      def method_missing(*args, &block)
        report.send *args, &block
      end

      def select_clause
        SQLBuilder::ClauseBuilder.new(document_id).compose(
          presenters_to_select(field_presenters),
          presenters_to_select(attribute_presenters)
        ).separated
      end

      def where_clause(for_range = false)
        builder = SQLBuilder::ClauseBuilder.new(nil)
        builder.add_clause inheritance_column_condition unless model.descends_from_active_record?
        builder.add_clause delta_processor.clause(source.delta?) if delta_processor
        builder.add_clause range_condition unless for_range
        builder.separated(' AND ')
      end

      def group_clause
        builder = SQLBuilder::ClauseBuilder.new(quoted_primary_key)

        builder.compose(
          presenters_to_group(field_presenters),
          presenters_to_group(attribute_presenters)
        ) unless source.options[:minimal_group_by?]

        builder.compose(groupings).separated
      end
    end
  end
end
