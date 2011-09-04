class ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter <
  ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter

  def convert_nulls(clause, default = '')
    "IFNULL(#{clause}, #{default})"
  end
end
