module Cucumber
  module ThinkingSphinx
    module SqlLogger
      IGNORED_SQL = [
        /^PRAGMA/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/,
        /^SELECT @@ROWCOUNT/, /^SHOW FIELDS/
      ]

      def log(sql, name = 'SQL', binds = [])
        $queries_executed ||= []
        $queries_executed << sql unless IGNORED_SQL.any? { |r| sql =~ r }
        super sql, name, binds
      end
    end
  end
end
