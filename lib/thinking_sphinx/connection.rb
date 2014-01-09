module ThinkingSphinx::Connection
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

    connection_class.new address, options[:port], options
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
          raise original if original.is_a?(ThinkingSphinx::QueryError)
          raise Innertube::Pool::BadResource
        end
      end
    rescue Innertube::Pool::BadResource
      retries += 1
      raise original unless retries < 3

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
    def close
      client.close unless ThinkingSphinx::Connection.persistent?
    end

    def execute(statement)
      query(statement).first
    end

    def query_all(*statements)
      query *statements
    end

    private

    def close_and_clear
      client.close
      @client = nil
    end
  end

  class MRI < Client
    def initialize(address, port, options)
      @address, @port, @options = address, port, options
    end

    def base_error
      Mysql2::Error
    end

    private

    attr_reader :address, :port, :options

    def client
      @client ||= Mysql2::Client.new({
        :host  => address,
        :port  => port,
        :flags => Mysql2::Client::MULTI_STATEMENTS
      }.merge(options))
    rescue base_error => error
      raise ThinkingSphinx::SphinxError.new_from_mysql error
    end

    def query(*statements)
      results  = [client.query(statements.join('; '))]
      results << client.store_result while client.next_result
      results
    rescue => error
      wrapper           = ThinkingSphinx::QueryExecutionError.new error.message
      wrapper.statement = statements.join('; ')
      raise wrapper
    ensure
      close_and_clear unless ThinkingSphinx::Connection.persistent?
    end
  end

  class JRuby < Client
    attr_reader :address, :options

    def initialize(address, port, options)
      @address = "jdbc:mysql://#{address}:#{port}?allowMultiQueries=true"
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

    def query(*statements)
      statement = client.createStatement
      statement.execute statements.join('; ')

      results   = [set_to_array(statement.getResultSet)]
      results  << set_to_array(statement.getResultSet) while statement.getMoreResults
      results.compact
    rescue => error
      wrapper           = ThinkingSphinx::QueryExecutionError.new error.message
      wrapper.statement = statements.join('; ')
      raise wrapper
    ensure
      close_and_clear unless ThinkingSphinx::Connection.persistent?
    end

    def set_to_array(set)
      return nil if set.nil?

      meta = set.meta_data
      rows = []

      while set.next
        row = {}

        (1..meta.column_count).each do |index|
          name      = meta.column_name index
          row[name] = case meta.column_type(index)
            when -6, 5, 4
              # TINYINT, INTEGER
              set.get_int(index).to_i
            when -5
              # BIGINT
              set.get_long(index).to_i
            when 41
              # Date
              set.get_date(index)
            when 92
              # Time
              set.get_time(index).to_i
            when 93
              # Timestamp
              set.get_timestamp(index)
            when 2, 3, 6
              # NUMERIC, DECIMAL, FLOAT
              case meta.scale(index)
              when 0
                set.get_long(index).to_i
              else
                BigDecimal.new(set.get_string(index).to_s)
              end
            when 1, -15, -9, 12
              # CHAR, NCHAR, NVARCHAR, VARCHAR
              set.get_string(index).to_s
            else
              set.get_string(index).to_s
            end
          end

        rows << row
      end
      rows
    end
  end
end
