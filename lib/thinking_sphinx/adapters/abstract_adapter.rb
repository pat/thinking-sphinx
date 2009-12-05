module ThinkingSphinx
  class AbstractAdapter
    def initialize(model)
      @model = model
    end
    
    def setup
      # Deliberately blank - subclasses should do something though. Well, if
      # they need to.
    end
      
    def self.detect(type, klass)
      case type
      when :mysql
        ThinkingSphinx::MysqlAdapter.new klass
      when :postgresql
        ThinkingSphinx::PostgreSQLAdapter.new klass
      else
        raise "Invalid Database Adapter: Sphinx only supports MySQL and PostgreSQL, not #{type}"
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
