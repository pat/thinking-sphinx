module ThinkingSphinx
  class PostgreSQLAdapter < AbstractAdapter
    class << self
      def setup
        create_array_accum_function
        create_crc32_function
      end
      
      private
      
      def create_array_accum_function
        connection.execute "begin"
        connection.execute "savepoint ts"
        begin
          # See http://www.postgresql.org/docs/8.2/interactive/sql-createaggregate.html
          if connection.raw_connection.server_version > 80200
            connection.execute <<-SQL
              CREATE AGGREGATE array_accum (anyelement)
              (
                  sfunc = array_append,
                  stype = anyarray,
                  initcond = '{}'
              );
            SQL
          else
            connection.execute <<-SQL
              CREATE AGGREGATE array_accum
              (
                  basetype = anyelement,
                  sfunc = array_append,
                  stype = anyarray,
                  initcond = '{}'
              );
            SQL
          end
        rescue
          connection.execute "rollback to savepoint ts"
        end
        connection.execute "release savepoint ts"
        connection.execute "commit"
      end
      
      def create_crc32_function
        connection.execute "begin"
        connection.execute "savepoint ts"
        begin
          connection.execute "CREATE LANGUAGE 'plpgsql';"
          connection.execute <<-SQL
            CREATE OR REPLACE FUNCTION crc32(word text)
            RETURNS bigint AS $$
              DECLARE tmp bigint;
              DECLARE i int;
              DECLARE j int;
              BEGIN
                i = 0;
                tmp = 4294967295;
                LOOP
                  tmp = (tmp # get_byte(word::bytea, i))::bigint;
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
        rescue
          connection.execute "rollback to savepoint ts"
        end
        connection.execute "release savepoint ts"
        connection.execute "commit"
      end
    end
  end
end