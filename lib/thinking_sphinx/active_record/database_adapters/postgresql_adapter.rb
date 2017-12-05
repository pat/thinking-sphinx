# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter <
  ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter

  def boolean_value(value)
    value ? 'TRUE' : 'FALSE'
  end

  def cast_to_bigint(clause)
    "#{clause}::bigint"
  end

  def cast_to_string(clause)
    "#{clause}::varchar"
  end

  def cast_to_timestamp(clause)
    if ThinkingSphinx::Configuration.instance.settings['64bit_timestamps']
      "extract(epoch from #{clause})::bigint"
    else
      "extract(epoch from #{clause})::int"
    end
  end

  def concatenate(clause, separator = ' ')
    clause.split(', ').collect { |part|
      convert_nulls(part, "''")
    }.join(" || '#{separator}' || ")
  end

  def convert_nulls(clause, default = '')
    "COALESCE(#{clause}, #{default})"
  end

  def convert_blank(clause, default = '')
    "COALESCE(NULLIF(#{clause}, ''), #{default})"
  end

  def group_concatenate(clause, separator = ' ')
    "array_to_string(array_agg(DISTINCT #{clause}), '#{separator}')"
  end

  def time_zone_query_pre
    ['SET TIME ZONE UTC']
  end
end
