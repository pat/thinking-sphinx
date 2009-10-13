module Cucumber
  module ThinkingSphinx
    module SqlLogger
      def self.included(base)
        base.send :alias_method_chain, :execute, :query_record
      end
      
      IGNORED_SQL = [
        /^PRAGMA/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/,
        /^SELECT @@ROWCOUNT/, /^SHOW FIELDS/
      ]
      
      def execute_with_query_record(sql, name = nil, &block)
        $queries_executed ||= []
        $queries_executed << sql unless IGNORED_SQL.any? { |r| sql =~ r }
        execute_without_query_record(sql, name, &block)
      end
    end
  end
end
