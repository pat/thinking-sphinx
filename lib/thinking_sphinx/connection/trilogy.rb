# lib/trilogy.rb

class ThinkingSphinx::Connection::Trilogy < ThinkingSphinx::Connection::Client
  def base_error
    ::Trilogy::Error
  end

  private

  attr_reader :options

  def client
    @client ||= Trilogy.new({
      :multi_statement => true,
      :connect_timeout => 5
    }.merge(options))
  rescue base_error => error
    raise ThinkingSphinx::SphinxError.new_from_mysql error
  end

  def results_for(statements)
    results  = [client.query(statements)]
    results << client.next_result while client.more_results_exist?
    results.map(&:each_hash)
  end
end
