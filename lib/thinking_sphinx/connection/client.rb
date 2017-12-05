# frozen_string_literal: true

class ThinkingSphinx::Connection::Client
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
    if statements.length > ThinkingSphinx::MAXIMUM_STATEMENT_LENGTH
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
