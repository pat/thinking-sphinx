class ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter <
  ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter

  def boolean_value(value)
    value ? 'TRUE' : 'FALSE'
  end

  def cast_to_string(clause)
    "#{clause}::varchar"
  end

  def cast_to_timestamp(clause)
    "extract(epoch from #{clause})::int"
  end

  def concatenate(clause, separator = ' ')
    clause.split(', ').collect { |part|
      convert_nulls(part, "''")
    }.join(" || '#{separator}' || ")
  end

  def convert_nulls(clause, default = '')
    "COALESCE(#{clause}, #{default})"
  end

  def group_concatenate(clause, separator = ' ')
    "array_to_string(array_agg(#{clause}), '#{separator}')"
  end
end
