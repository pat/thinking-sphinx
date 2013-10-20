module ThinkingSphinx
  module ActiveRecord
    class SQLBuilder::Query
      def initialize(report)
        self.report = report
        self.scope = []
      end

      def to_query
        filter_by_query_pre

        scope.compact
      end

      protected

      attr_accessor :report, :scope

      def filter_by_query_pre
        scope_by_time_zone
        scope_by_delta_processor
        scope_by_session
        scope_by_utf8
      end

      def scope_by_delta_processor
        self.scope << delta_processor.reset_query if delta_processor && !source.delta?
      end

      def scope_by_session
        if max_len = source.options[:group_concat_max_len]
          self.scope << "SET SESSION group_concat_max_len = #{max_len}"
        end
      end

      def scope_by_time_zone
        return if config.settings['skip_time_zone']

        self.scope += time_zone_query_pre
      end

      def scope_by_utf8
        self.scope += utf8_query_pre if source.options[:utf8?]
      end

      def method_missing(*args, &block)
        report.send *args, &block
      end
    end
  end
end
