module ThinkingSphinx
  class AbstractAdapter
    class << self
      def setup
        # Deliberately blank - subclasses should do something though. Well, if
        # they need to.
      end
      
      def detect(model)
        case model.connection.class.name
        when "ActiveRecord::ConnectionAdapters::MysqlAdapter"
          ThinkingSphinx::MysqlAdapter
        when "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
          ThinkingSphinx::PostgreSQLAdapter
        else
          raise "Invalid Database Adapter: Sphinx only supports MySQL and PostgreSQL"
        end
      end
      
      protected
      
      def connection
        @connection ||= ::ActiveRecord::Base.connection
      end
    end
  end
end