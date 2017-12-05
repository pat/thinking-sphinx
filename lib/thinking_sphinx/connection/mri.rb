# frozen_string_literal: true

class ThinkingSphinx::Connection::MRI < ThinkingSphinx::Connection::Client
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
      :flags           => Mysql2::Client::MULTI_STATEMENTS,
      :connect_timeout => 5
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
