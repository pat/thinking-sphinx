class ThinkingSphinx::Connection
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
        connection.reset
        begin
          yield connection
        rescue Riddle::ConnectionError, Riddle::ResponseError, SystemCallError => error
          original = error
          raise Innertube::Pool::BadResource
        end
      end
    rescue Innertube::Pool::BadResource
      retries += 1
      retry if retries < 3
      raise original
    end
  end

  def initialize
    client.open
  end

  def client
    @client ||= begin
      client = Riddle::Client.new shuffled_addresses, configuration.port,
        client_key
      client.max_matches = _max_matches
      client.timeout     = configuration.timeout || 0
      client
    end
  end

  private

  def client_key
    configuration.configuration.searchd.client_key
  end

  def configuration
    ThinkingSphinx::Configuration.instance
  end

  def _max_matches
    configuration.configuration.searchd.max_matches || 1000
  end

  def method_missing(method, *arguments, &block)
    client.send method, *arguments, &block
  end

  def shuffled_addresses
    return configuration.address unless configuration.shuffle

    addresses = Array(configuration.address)
    if addresses.respond_to?(:shuffle)
      addresses.shuffle
    else
      address.sort_by { rand }
    end
  end
end
