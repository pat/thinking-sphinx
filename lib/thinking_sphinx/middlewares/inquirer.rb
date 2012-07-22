class ThinkingSphinx::Middlewares::Inquirer <
  ThinkingSphinx::Middlewares::Middleware

  def call(context)
    @context  = context
    reset_memos

    log :query, sphinxql do
      context[:results] = raw
      context[:raw]     = raw
      context[:meta]    = meta
    end

    total = meta['total_found']
    log :message, "Found #{total} result#{'s' unless total == 1}"

    app.call context
  end

  private

  def connection
    @connection ||= context.configuration.connection
  end

  def log(notification, message, &block)
    ActiveSupport::Notifications.instrument(
      "#{notification}.thinking_sphinx", notification => message, &block
    )
  end

  def meta
    @meta ||= connection.query(Riddle::Query.meta).inject({}) { |hash, row|
      hash[row['Variable_name']] = row['Value']
      hash
    }
  end

  def raw
    @raw ||= connection.query sphinxql
  end

  def reset_memos
    @connection = nil
    @meta       = nil
    @raw        = nil
    @sphinxql   = nil
  end

  def sphinxql
    @sphinxql ||= context[:sphinxql].to_sql
  end
end
