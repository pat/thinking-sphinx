module ThinkingSphinx::ActiveRecord::DatabaseAdapters
  class << self
    attr_accessor :default

    def adapter_for(model)
      return default.new(model) if default

      adapter = adapter_type_for(model)
      klass   = case adapter
      when :mysql
        MySQLAdapter
      when :postgresql
        PostgreSQLAdapter
      else
        raise ThinkingSphinx::InvalidDatabaseAdapter, "Invalid adapter '#{adapter}': Thinking Sphinx only supports MySQL and PostgreSQL."
      end

      klass.new model
    end

    def adapter_type_for(model)
      class_name = model.connection.class.name
      case class_name.split('::').last
      when 'MysqlAdapter', 'Mysql2Adapter'
        :mysql
      when 'PostgreSQLAdapter', 'MainAdapter'
        :postgresql
      when 'JdbcAdapter'
        adapter_type_for_jdbc(model)
      else
        class_name
      end
    end

    def adapter_type_for_jdbc(model)
      case adapter = model.connection.config[:adapter]
      when 'jdbcmysql'
        :mysql
      when 'jdbcpostgresql'
        :postgresql
      when 'jdbc'
        adapter_type_for_jdbc_plain(adapter, model.connection.config[:url])
      else adapter
      end
    end

    def adapter_type_for_jdbc_plain(adapter, url)
      return adapter unless match = /^jdbc:(?<adapter>mysql|postgresql):\/\//.match(url)

      match[:adapter].to_sym
    end
  end
end

require 'thinking_sphinx/active_record/database_adapters/abstract_adapter'
require 'thinking_sphinx/active_record/database_adapters/mysql_adapter'
require 'thinking_sphinx/active_record/database_adapters/postgresql_adapter'
