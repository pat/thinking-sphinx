class ThinkingSphinx::Middlewares::Inquirer <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    @contexts = contexts
    @batch    = nil

    log :query, combined_queries do
      batch.results
    end

    index = 0
    contexts.each do |context|
      raw = batch.results[index]
      meta = batch.results[index + 1].inject({}) { |hash, row|
        hash[row['Variable_name']] = row['Value']
        hash
      }

      context[:results] = raw
      context[:raw]     = raw
      context[:meta]    = meta

      total = meta['total_found']
      log :message, "Found #{total} result#{'s' unless total == 1}"

      index += 2
    end

    app.call contexts
  end

  private

  def batch
    @batch ||= begin
      batch = ThinkingSphinx::Search::BatchInquirer.new

      @contexts.each do |context|
        batch.append_query context[:sphinxql].to_sql
        batch.append_query Riddle::Query.meta
      end

      batch
    end
  end

  def combined_queries
    @contexts.collect { |context| context[:sphinxql].to_sql }.join('; ')
  end

  def log(notification, message, &block)
    ActiveSupport::Notifications.instrument(
      "#{notification}.thinking_sphinx", notification => message, &block
    )
  end
end
