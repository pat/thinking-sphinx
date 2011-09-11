class ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter <
  ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter

  def convert_nulls(clause, default = '')
    "COALESCE(#{clause}, #{default})"
  end
end
