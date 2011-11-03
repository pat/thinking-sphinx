module Riddle
  class Configuration
    class SQLSource < Riddle::Configuration::Source
      def self.settings
        [
          :type, :sql_host, :sql_user, :sql_pass, :sql_db,
          :sql_port, :sql_sock, :mysql_connect_flags, :mysql_ssl_cert,
          :mysql_ssl_key, :mysql_ssl_ca, :odbc_dsn, :sql_query_pre, :sql_query,
          :sql_joined_field, :sql_file_field, :sql_query_range, :sql_range_step,
          :sql_query_killlist, :sql_attr_uint, :sql_attr_bool, :sql_attr_bigint,
          :sql_attr_timestamp, :sql_attr_str2ordinal, :sql_attr_float,
          :sql_attr_multi, :sql_attr_string, :sql_attr_str2wordcount,
          :sql_column_buffers, :sql_field_string, :sql_field_str2wordcount,
          :sql_query_post, :sql_query_post_index, :sql_ranged_throttle,
          :sql_query_info, :mssql_winauth, :mssql_unicode, :unpack_zlib,
          :unpack_mysqlcompress, :unpack_mysqlcompress_maxsize
        ]
      end

      attr_accessor *self.settings

      def initialize(name, type)
        @name = name
        @type = type

        @sql_query_pre            = []
        @sql_joined_field         = []
        @sql_file_field           = []
        @sql_attr_uint            = []
        @sql_attr_bool            = []
        @sql_attr_bigint          = []
        @sql_attr_timestamp       = []
        @sql_attr_str2ordinal     = []
        @sql_attr_float           = []
        @sql_attr_multi           = []
        @sql_attr_string          = []
        @sql_attr_str2wordcount   = []
        @sql_field_string         = []
        @sql_field_str2wordcount  = []
        @sql_query_post           = []
        @sql_query_post_index     = []
        @unpack_zlib              = []
        @unpack_mysqlcompress     = []
      end

      def valid?
        super && (!( @sql_host.nil? || @sql_user.nil? || @sql_db.nil? ||
          @sql_query.nil? ) || !@parent.nil?)
      end
    end
  end
end
