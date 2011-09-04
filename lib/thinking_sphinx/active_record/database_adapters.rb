module ThinkingSphinx::ActiveRecord::DatabaseAdapters
  def self.adapter_for(model)
    return default.new(model) unless default.nil?

    adapter = adapter_type_for(model)
    klass   = case adapter
    when :mysql
      ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter
    when :postgresql
      ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter
    else
      raise "Invalid Database Adapter '#{adapter}': Thinking Sphinx only supports MySQL and PostgreSQL."
    end

    klass.new model
  end

  def self.adapter_type_for(model)
    case model.connection.class.name
    when "ActiveRecord::ConnectionAdapters::MysqlAdapter",
         "ActiveRecord::ConnectionAdapters::Mysql2Adapter"
      :mysql
    when "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
      :postgresql
    when "ActiveRecord::ConnectionAdapters::JdbcAdapter"
      case model.connection.config[:adapter]
      when "jdbcmysql"
        :mysql
      when "jdbcpostgresql"
        :postgresql
      else
        model.connection.config[:adapter]
      end
    else
      model.connection.class.name
    end
  end

  @default = nil
  def self.default
    @default
  end

  def self.default=(default)
    @default = default
  end
end

require 'thinking_sphinx/active_record/database_adapters/abstract_adapter'
require 'thinking_sphinx/active_record/database_adapters/mysql_adapter'
require 'thinking_sphinx/active_record/database_adapters/postgresql_adapter'
