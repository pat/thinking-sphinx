module ThinkingSphinx::Connection
  MAXIMUM_RETRIES = 3

  def self.new
    configuration = ThinkingSphinx::Configuration.instance
    # If you use localhost, MySQL insists on a socket connection, but Sphinx
    # requires a TCP connection. Using 127.0.0.1 fixes that.
    address = configuration.searchd.address || '127.0.0.1'
    address = '127.0.0.1' if address == 'localhost'

    options = {
      :host      => address,
      :port      => configuration.searchd.mysql41,
      :reconnect => true
    }.merge(configuration.settings['connection_options'] || {})

    connection_class.new options
  end

  def self.connection_class
    return ThinkingSphinx::Connection::JRuby if RUBY_PLATFORM == 'java'

    ThinkingSphinx::Connection::MRI
  end

  def self.pool
    @pool ||= Innertube::Pool.new(
      Proc.new { ThinkingSphinx::Connection.new },
      Proc.new { |connection| connection.close }
    )
  end

  def self.take
    retries  = 0
    original = nil
    begin
      pool.take do |connection|
        begin
          yield connection
        rescue ThinkingSphinx::QueryExecutionError, connection.base_error => error
          original = ThinkingSphinx::SphinxError.new_from_mysql error
          retries += MAXIMUM_RETRIES if original.is_a?(ThinkingSphinx::QueryError)
          raise Innertube::Pool::BadResource
        end
      end
    rescue Innertube::Pool::BadResource
      retries += 1
      raise original unless retries < MAXIMUM_RETRIES

      ActiveSupport::Notifications.instrument(
        "message.thinking_sphinx", :message => "Retrying query \"#{original.statement}\" after error: #{original.message}"
      )
      retry
    end
  end

  def self.persistent?
    @persistent
  end

  def self.persistent=(persist)
    @persistent = persist
  end

  @persistent = true

  class Client
    MAXIMUM_LENGTH = (2 ** 23) - 1

    def close
      client.close unless ThinkingSphinx::Connection.persistent?
    end

    def execute(statement)
      check_and_perform(statement).first
    end

    def query_all(*statements)
      check_and_perform statements.join('; ')
    end

    private

    def check(statements)
      if statements.length > MAXIMUM_LENGTH
        raise ThinkingSphinx::QueryLengthError, "Query is #{statements.length} long, and can not be longer than #{MAXIMUM_LENGTH}"
      end
    end

    def check_and_perform(statements)
      check statements
      perform statements
    end

    def close_and_clear
      client.close
      @client = nil
    end

    def perform(statements)
      results_for statements
    rescue => error
      message           = "#{error.message} - #{statements}"
      wrapper           = ThinkingSphinx::QueryExecutionError.new message
      wrapper.statement = statements
      raise wrapper
    ensure
      close_and_clear unless ThinkingSphinx::Connection.persistent?
    end
  end

  class MRI < Client
    def initialize(options)
      @options = options
    end

    def base_error
      Mysql2::Error
    end

    private

    attr_reader :options

    def client
      @client ||= Mysql2::Client.new({
        :flags => Mysql2::Client::MULTI_STATEMENTS
      }.merge(options))
    rescue base_error => error
      raise ThinkingSphinx::SphinxError.new_from_mysql error
    end

    def results_for(statements)
      results  = [client.query(statements)]
      results << client.store_result while client.next_result
      results
    end
  end

  class JRuby < Client
    attr_reader :address, :options

    def initialize(options)
      @address = "jdbc:mysql://#{options[:host]}:#{options[:port]}/?allowMultiQueries=true"
      @options = options
    end

    def base_error
      Java::JavaSql::SQLException
    end

    private

    def client
      @client ||= java.sql.DriverManager.getConnection address,
        options[:username], options[:password]
    rescue base_error => error
      raise ThinkingSphinx::SphinxError.new_from_mysql error
    end

    def results_for(statements)
      statement = client.createStatement
      statement.execute statements

      results   = [set_to_array(statement.getResultSet)]
      results  << set_to_array(statement.getResultSet) while statement.getMoreResults
      results.compact
    end

    def set_to_array(set)
      return nil if set.nil?

      meta = set.getMetaData
      rows = []

      while set.next
        rows << (1..meta.getColumnCount).inject({}) do |row, index|
          name      = meta.getColumnName index
          row[name] = set.getObject(index)
          row
        end
      end

      rows
    end
  end
end
