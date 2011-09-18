class ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter <
  ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter

  def cast_to_timestamp(clause)
    "cast(extract(epoch from #{clause}) as int)"
  end

  def convert_nulls(clause, default = '')
    "COALESCE(#{clause}, #{default})"
  end

  def group_concatenate(clause, separator = ' ')
    "array_to_string(array_agg(#{clause}), '#{separator}')"
  end
end
