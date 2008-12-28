module ThinkingSphinx
  class PostgreSQLAdapter < AbstractAdapter
    class << self
      def setup
        create_array_accum_function
        create_crc32_function
      end
      
      private
      
      def execute(command)
        connection.execute "begin"
        connection.execute "savepoint ts"
        begin
          connection.execute command
        rescue
          connection.execute "rollback to savepoint ts"
        end
        connection.execute "release savepoint ts"
        connection.execute "commit"
      end
      
      def create_array_accum_function
        if connection.raw_connection.server_version > 80200
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
        execute <<-SQL
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
      end
    end
  end
end