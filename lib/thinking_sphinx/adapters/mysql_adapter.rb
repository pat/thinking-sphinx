module ThinkingSphinx
  class MysqlAdapter < AbstractAdapter
    def setup
      # Does MySQL actually need to do anything?
    end
    
    def concatenate(clause, separator = ' ')
      "CONCAT_WS('#{separator}', #{clause})"
    end
    
    def group_concatenate(clause, separator = ' ')
      "GROUP_CONCAT(#{clause} SEPARATOR '#{separator}')"
    end
    
    def cast_to_string(clause)
      "CAST(#{clause} AS CHAR)"
    end
    
    def cast_to_datetime(clause)
      "UNIX_TIMESTAMP(#{clause})"
    end
    
    def convert_nulls(clause)
      "IFNULL(#{clause}, '')"
    end
  end
end