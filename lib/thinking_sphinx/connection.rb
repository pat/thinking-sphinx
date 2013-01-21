module ThinkingSphinx::Connection
  def self.new
    configuration = ThinkingSphinx::Configuration.instance
    # If you use localhost, MySQL insists on a socket connection, but Sphinx
    # requires a TCP connection. Using 127.0.0.1 fixes that.
    address = configuration.searchd.address || '127.0.0.1'
    address = '127.0.0.1' if address == 'localhost'

    options = {
      :host  => address,
      :port  => configuration.searchd.mysql41
    }.merge(configuration.settings['connection_options'] || {})

    connection_class.new address, options[:port], options
  end

  def self.connection_class
    raise "Sphinx's MySQL protocol does not work with JDBC." if RUBY_PLATFORM == 'java'
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
    retries = 0
    begin
      pool.take do |connection|
        begin
          yield connection
        rescue Mysql2::Error
          raise Innertube::Pool::BadResource
        end
      end
    rescue Innertube::Pool::BadResource
      retries += 1
      retry if retries < 3
      raise
    end
  end

  class MRI
    attr_reader :client

    def initialize(address, port, options)
      @client = Mysql2::Client.new({
        :host  => address,
        :port  => port,
        :flags => Mysql2::Client::MULTI_STATEMENTS
      }.merge(options))
    end

    def close
      client.close
    end

    def execute(statement)
      client.query statement
    rescue
      puts "Error with statement: #{statement}"
      raise
    end

    def query(statement)
      client.query statement
    end

    def query_all(*statements)
      results  = [client.query(statements.join('; '))]
      results << client.store_result while client.next_result
      results
    end
  end

  class JRuby
    attr_reader :client

    def initialize(address, port, options)
      address = "jdbc:mysql://#{address}:#{searchd.mysql41}"
      @client = java.sql.DriverManager.getConnection address,
        options[:username], options[:password]
    end

    def execute(statement)
      client.createStatement.execute statement
    end

    def query(statement)
      #
    end

    def query_all(*statements)
      #
    end
  end
end
