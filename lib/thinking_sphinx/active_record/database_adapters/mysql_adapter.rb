class ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter <
  ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter

  def cast_to_timestamp(clause)
    "UNIX_TIMESTAMP(#{clause})"
  end

  def convert_nulls(clause, default = '')
    "IFNULL(#{clause}, #{default})"
  end
end
