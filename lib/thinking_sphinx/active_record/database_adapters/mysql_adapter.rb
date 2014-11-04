class ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter <
  ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter

  def boolean_value(value)
    value ? 1 : 0
  end

  def cast_to_bigint(clause)
    "CAST(#{clause} AS UNSIGNED INTEGER)"
  end

  def cast_to_string(clause)
    "CAST(#{clause} AS char)"
  end

  def cast_to_timestamp(clause)
    "UNIX_TIMESTAMP(#{clause})"
  end

  def concatenate(clause, separator = ' ')
    "CONCAT_WS('#{separator}', #{clause})"
  end

  def convert_nulls(clause, default = '')
    "IFNULL(#{clause}, #{default})"
  end

  def convert_blank(clause, default = '')
    "COALESCE(NULLIF(#{clause}, ''), #{default})"
  end

  def group_concatenate(clause, separator = ' ')
    "GROUP_CONCAT(DISTINCT #{clause} SEPARATOR '#{separator}')"
  end

  def time_zone_query_pre
    ["SET TIME_ZONE = '+0:00'"]
  end

  def utf8_query_pre
    ['SET NAMES utf8']
  end
end
