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
      case model.connection.class.name
      when "ActiveRecord::ConnectionAdapters::MysqlAdapter"
        ThinkingSphinx::MysqlAdapter.new model
      when "ActiveRecord::ConnectionAdapters::MysqlplusAdapter"
        ThinkingSphinx::MysqlAdapter.new model
      when "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
        ThinkingSphinx::PostgreSQLAdapter.new model
      else
        raise "Invalid Database Adapter: Sphinx only supports MySQL and PostgreSQL"
      end
    end
    
    def quote_with_table(column)
      "#{@model.quoted_table_name}.#{@model.connection.quote_column_name(column)}"
    end
    
    protected
    
    def connection
      @connection ||= @model.connection
    end
  end
end
