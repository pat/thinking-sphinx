module Riddle
  class Configuration
    class Searchd < Riddle::Configuration::Section
      def self.settings
        [
          :listen, :address, :port, :log, :query_log,
          :query_log_format, :read_timeout, :client_timeout, :max_children,
          :pid_file, :max_matches, :seamless_rotate, :preopen_indexes,
          :unlink_old, :attr_flush_period, :ondisk_dict_default, :max_packet_size,
          :mva_updates_pool, :crash_log_path, :max_filters, :max_filter_values,
          :listen_backlog, :read_buffer, :read_unhinted, :max_batch_queries,
          :subtree_docs_cache, :subtree_hits_cache, :workers, :dist_threads,
          :binlog_path, :binlog_flush, :binlog_max_log_size, :collation_server,
          :collation_libc_locale, :plugin_dir, :mysql_version_string,
          :rt_flush_period, :thread_stack, :expansion_limit,
        :compat_sphinxql_magics, :watchdog, :client_key
        ]
      end
      
      attr_accessor *self.settings
      attr_accessor :mysql41
            
      def render
        raise ConfigurationError unless valid?
        
        (
          ["searchd", "{"] +
          settings_body +
          ["}", ""]
        ).join("\n")
      end
      
      def valid?
        !( @port.nil? || @pid_file.nil? )
      end
    end
  end
end
