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

  def batch
    @batch ||= ThinkingSphinx::Search::BatchInquirer.new do |batch|
      batch.append_query sphinxql
      batch.append_query Riddle::Query.meta
    end
  end

  def log(notification, message, &block)
    ActiveSupport::Notifications.instrument(
      "#{notification}.thinking_sphinx", notification => message, &block
    )
  end

  def meta
    @meta ||= batch.results[1].inject({}) { |hash, row|
      hash[row['Variable_name']] = row['Value']
      hash
    }
  end

  def raw
    @raw ||= batch.results[0]
  end

  def reset_memos
    @batch    = nil
    @meta     = nil
    @raw      = nil
    @sphinxql = nil
  end

  def sphinxql
    @sphinxql ||= context[:sphinxql].to_sql
  end
end
