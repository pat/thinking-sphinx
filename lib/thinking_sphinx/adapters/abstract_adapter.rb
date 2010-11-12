module ThinkingSphinx
  class AbstractAdapter
    def initialize(model)
      @model = model
    end
    
    def setup
      # Deliberately blank - subclasses should do something though. Well, if
      # they need to.
    end
      
    def self.detect(model)
      adapter = adapter_for_model model
      case adapter
      when :mysql
        ThinkingSphinx::MysqlAdapter.new model
      when :postgresql
        ThinkingSphinx::PostgreSQLAdapter.new model
      else
        raise "Invalid Database Adapter: Sphinx only supports MySQL and PostgreSQL, not #{adapter}"
      end
    end
    
    def self.adapter_for_model(model)
      case ThinkingSphinx.database_adapter
      when String
        ThinkingSphinx.database_adapter.to_sym
      when NilClass
        standard_adapter_for_model model
      when Proc
        ThinkingSphinx.database_adapter.call model
      else
        ThinkingSphinx.database_adapter
      end
    end
    
    def self.standard_adapter_for_model(model)
      case model.connection.class.name
      when "ActiveRecord::ConnectionAdapters::MysqlAdapter",
           "ActiveRecord::ConnectionAdapters::MysqlplusAdapter",
           "ActiveRecord::ConnectionAdapters::Mysql2Adapter",
           "ActiveRecord::ConnectionAdapters::NullDBAdapter"
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
    
    def quote_with_table(column)
      "#{@model.quoted_table_name}.#{@model.connection.quote_column_name(column)}"
    end
    
    def bigint_pattern
      /bigint/i
    end
    
    protected
    
    def connection
      @connection ||= @model.connection
    end
  end
end
