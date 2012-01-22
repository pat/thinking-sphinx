module Cucumber
  module ThinkingSphinx
    module SqlLogger
      IGNORED_SQL = [
        /^PRAGMA/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/,
        /^SELECT @@ROWCOUNT/, /^SHOW FIELDS/
      ]

      if ActiveRecord::VERSION::STRING.to_f > 3.0
        def log(sql, name = 'SQL', binds = [])
          $queries_executed ||= []
          $queries_executed << sql unless IGNORED_SQL.any? { |r| sql =~ r }
          super sql, name, binds
        end
      else
        def self.included(base)
          base.send :alias_method_chain, :execute, :query_record
        end

        def execute_with_query_record(sql, name = 'SQL', &block)
          $queries_executed ||= []
          $queries_executed << sql unless IGNORED_SQL.any? { |r| sql =~ r }
          execute_without_query_record(sql, name, &block)
        end
      end
    end
  end
end
