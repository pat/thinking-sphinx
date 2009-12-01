module Riddle
  class Configuration
    class SQLSource < Riddle::Configuration::Source
      self.settings = [:type, :sql_host, :sql_user, :sql_pass, :sql_db,
        :sql_port, :sql_sock, :mysql_connect_flags, :mysql_ssl_cert,
        :mysql_ssl_key, :mysql_ssl_ca, :odbc_dsn, :sql_query_pre, :sql_query,
        :sql_query_range, :sql_range_step, :sql_query_killlist, :sql_attr_uint,
        :sql_attr_bool, :sql_attr_bigint, :sql_attr_timestamp,
        :sql_attr_str2ordinal, :sql_attr_float, :sql_attr_multi,
        :sql_query_post, :sql_query_post_index, :sql_ranged_throttle,
        :sql_query_info, :mssql_winauth, :mssql_unicode, :unpack_zlib,
        :unpack_mysqlcompress, :unpack_mysqlcompress_maxsize]
      
      attr_accessor *self.settings
      
      def initialize(name, type)
        @name = name
        @type = type
        
        @sql_query_pre        = []
        @sql_attr_uint        = []
        @sql_attr_bool        = []
        @sql_attr_bigint      = []
        @sql_attr_timestamp   = []
        @sql_attr_str2ordinal = []
        @sql_attr_float       = []
        @sql_attr_multi       = []
        @sql_query_post       = []
        @sql_query_post_index = []
        @unpack_zlib          = []
        @unpack_mysqlcompress = []
      end
      
      def sql_query=(query)
        unless query.nil?
          max_length = 8178  # max is: 8192 - "sql_query = ".length - "\\\n".length
          i = max_length
          while i < query.length
            i = query.rindex(" ", i)
            query.insert(i, "\\" + "\n")
            i = i + max_length
          end
        end
        @sql_query = query
      end
            
      def valid?
        super && (!( @sql_host.nil? || @sql_user.nil? || @sql_db.nil? ||
          @sql_query.nil? ) || !@parent.nil?)
      end
    end
  end
end