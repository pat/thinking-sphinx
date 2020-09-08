# frozen_string_literal: true

class ThinkingSphinx::Connection::Client
  def initialize(options)
    if options[:socket].present?
      options[:socket] = options[:socket].remove /:mysql41$/

      options.delete :host
      options.delete :port
    else
      options.delete :socket

      # If you use localhost, MySQL insists on a socket connection, but in this
      # situation we want a TCP connection. Using 127.0.0.1 fixes that.
      if options[:host].nil? || options[:host] == "localhost"
        options[:host] = "127.0.0.1"
      end
    end

    @options = options
  end

  def close
    close! unless ThinkingSphinx::Connection.persistent?
  end

  def close!
    client.close
  end

  def execute(statement)
    check_and_perform(statement).first
  end

  def query_all(*statements)
    check_and_perform statements.join('; ')
  end

  private

  def check(statements)
    if statements.length > maximum_statement_length
      exception           = ThinkingSphinx::QueryLengthError.new
      exception.statement = statements
      raise exception
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

  def maximum_statement_length
    @maximum_statement_length ||= ThinkingSphinx::Configuration.instance.
      settings['maximum_statement_length']
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
