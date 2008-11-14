module Riddle
  class Configuration
    class SQLSource < Riddle::Configuration::Source
      self.settings = [:type, :sql_host, :sql_user, :sql_pass, :sql_db,
        :sql_port, :sql_sock, :mysql_connect_flags, :sql_query_pre, :sql_query,
        :sql_query_range, :sql_range_step, :sql_attr_uint, :sql_attr_bool,
        :sql_attr_timestamp, :sql_attr_str2ordinal, :sql_attr_float,
        :sql_attr_multi, :sql_query_post, :sql_query_post_index,
        :sql_ranged_throttle, :sql_query_info]
      
      attr_accessor *self.settings
      
      def initialize(name, type)
        @name = name
        @type = type
        
        @sql_query_pre        = []
        @sql_attr_uint        = []
        @sql_attr_bool        = []
        @sql_attr_timestamp   = []
        @sql_attr_str2ordinal = []
        @sql_attr_float       = []
        @sql_attr_multi       = []
        @sql_query_post       = []
        @sql_query_post_index = []
      end
            
      def valid?
        super && (!( @sql_host.nil? || @sql_user.nil? || @sql_db.nil? ||
          @sql_query.nil? ) || !@parent.nil?)
      end
    end
  end
end