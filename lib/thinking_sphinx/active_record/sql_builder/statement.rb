module ThinkingSphinx
  module ActiveRecord
    class SQLBuilder::Statement
      def initialize(report)
        self.report = report
        self.scope = relation
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

      protected
      attr_accessor :report, :scope

      def filter_by_query_range
        minimum = convert_nulls "MIN(#{quoted_primary_key})", 1
        maximum = convert_nulls "MAX(#{quoted_primary_key})", 1

        self.scope = scope.select("#{minimum}, #{maximum}").where(where_clause(true))
      end

      def filter_by_query_info
        self.scope = scope.where("#{quoted_primary_key} = #{reversed_document_id}")
      end

      def filter_by_query_pre
        self.scope = []

        scope_by_delta_processor
        scope_by_session
        scope_by_utf8

        scope.compact
      end

      def scope_by_delta_processor
        self.scope << delta_processor.reset_query if delta_processor && !source.delta?
      end

      def scope_by_session
        if max_len = source.options[:group_concat_max_len]
          self.scope << "SET SESSION group_concat_max_len = #{max_len}"
        end
      end

      def scope_by_utf8
        self.scope += utf8_query_pre if source.options[:utf8?]
      end

      def filter_by_scopes
        scope_by_select
        scope_by_where_clause
        scope_by_group_clause
        scope_by_joins
        scope_by_custom_joins
        scope_by_order
      end

      def scope_by_select
        self.scope = scope.select(pre_select + select_clause)
      end

      def scope_by_where_clause
        self.scope = scope.where where_clause
      end

      def scope_by_group_clause
        self.scope = scope.group(group_clause)
      end

      def scope_by_joins
        self.scope = scope.joins(associations.join_values)
      end

      def scope_by_custom_joins
        self.scope = scope.joins(custom_joins) if custom_joins.any?
      end

      def scope_by_order
        self.scope = scope.order('NULL') if source.type == 'mysql'
      end

      def method_missing(*args, &block)
        report.send *args, &block
      end
    end
  end
end
