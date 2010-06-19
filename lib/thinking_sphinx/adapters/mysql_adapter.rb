module ThinkingSphinx
  class MysqlAdapter < AbstractAdapter
    def setup
      # Does MySQL actually need to do anything?
    end
    
    def sphinx_identifier
      "mysql"
    end
    
    def concatenate(clause, separator = ' ')
      "CONCAT_WS('#{separator}', #{clause})"
    end
    
    def group_concatenate(clause, separator = ' ')
      "GROUP_CONCAT(DISTINCT IFNULL(#{clause}, '0') SEPARATOR '#{separator}')"
    end
    
    def cast_to_string(clause)
      "CAST(#{clause} AS CHAR)"
    end
    
    def cast_to_datetime(clause)
      "UNIX_TIMESTAMP(#{clause})"
    end
    
    def cast_to_unsigned(clause)
      "CAST(#{clause} AS UNSIGNED)"
    end
    
    def convert_nulls(clause, default = '')
      default = "'#{default}'" if default.is_a?(String)
      
      "IFNULL(#{clause}, #{default})"
    end
    
    def boolean(value)
      value ? 1 : 0
    end
    
    def crc(clause, blank_to_null = false)
      clause = "NULLIF(#{clause},'')" if blank_to_null
      "CRC32(#{clause})"
    end
    
    def utf8_query_pre
      "SET NAMES utf8"
    end
    
    def time_difference(diff)
      "DATE_SUB(NOW(), INTERVAL #{diff} SECOND)"
    end
    
    def utc_query_pre
      "SET TIME_ZONE = '+0:00'"
    end
  end
end
