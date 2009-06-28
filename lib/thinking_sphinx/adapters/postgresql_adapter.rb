module ThinkingSphinx
  class PostgreSQLAdapter < AbstractAdapter
    def setup
      create_array_accum_function
      create_crc32_function
    end
    
    def sphinx_identifier
      "pgsql"
    end
    
    def concatenate(clause, separator = ' ')
      clause.split(', ').collect { |field|
        case field
        when /COALESCE/, "'')"
          field
        else
          "COALESCE(CAST(#{field} as varchar), '')"
        end
      }.join(" || '#{separator}' || ")
    end
    
    def group_concatenate(clause, separator = ' ')
      "array_to_string(array_accum(#{clause}), '#{separator}')"
    end
    
    def cast_to_string(clause)
      clause
    end
    
    def cast_to_datetime(clause)
      "cast(extract(epoch from #{clause}) as int)"
    end
    
    def cast_to_unsigned(clause)
      clause
    end
    
    def convert_nulls(clause, default = '')
      default = "'#{default}'"  if default.is_a?(String)
      default = 'NULL'          if default.nil?
      
      "COALESCE(#{clause}, #{default})"
    end
    
    def boolean(value)
      value ? 'TRUE' : 'FALSE'
    end
    
    def crc(clause, blank_to_null = false)
      clause = "NULLIF(#{clause},'')" if blank_to_null
      "crc32(#{clause})"
    end
    
    def utf8_query_pre
      nil
    end
    
    def time_difference(diff)
      "current_timestamp - interval '#{diff} seconds'"
    end
    
    private
    
    def execute(command, output_error = false)
      connection.execute "begin"
      connection.execute "savepoint ts"
      begin
        connection.execute command
      rescue StandardError => err
        puts err if output_error
        connection.execute "rollback to savepoint ts"
      end
      connection.execute "release savepoint ts"
      connection.execute "commit"
    end
    
    def create_array_accum_function
      if connection.raw_connection.respond_to?(:server_version) && connection.raw_connection.server_version > 80200
        execute <<-SQL
          CREATE AGGREGATE array_accum (anyelement)
          (
              sfunc = array_append,
              stype = anyarray,
              initcond = '{}'
          );
        SQL
      else
        execute <<-SQL
          CREATE AGGREGATE array_accum
          (
              basetype = anyelement,
              sfunc = array_append,
              stype = anyarray,
              initcond = '{}'
          );
        SQL
      end
    end
    
    def create_crc32_function
      execute "CREATE LANGUAGE 'plpgsql';"
      function = <<-SQL
        CREATE OR REPLACE FUNCTION crc32(word text)
        RETURNS bigint AS $$
          DECLARE tmp bigint;
          DECLARE i int;
          DECLARE j int;
          DECLARE word_array bytea;
          BEGIN
            i = 0;
            tmp = 4294967295;
            word_array = decode(replace(word, E'\\\\', E'\\\\\\\\'), 'escape');
            LOOP
              tmp = (tmp # get_byte(word_array, i))::bigint;
              i = i + 1;
              j = 0;
              LOOP
                tmp = ((tmp >> 1) # (3988292384 * (tmp & 1)))::bigint;
                j = j + 1;
                IF j >= 8 THEN
                  EXIT;
                END IF;
              END LOOP;
              IF i >= char_length(word) THEN
                EXIT;
              END IF;
            END LOOP;
            return (tmp # 4294967295);
          END
        $$ IMMUTABLE STRICT LANGUAGE plpgsql;
      SQL
      execute function, true
    end
  end
end
