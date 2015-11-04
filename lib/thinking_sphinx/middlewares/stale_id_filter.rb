class ThinkingSphinx::Middlewares::StaleIdFilter <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    @context   = contexts.first
    @stale_ids = []
    @retries   = stale_retries

    begin
      app.call contexts
    rescue ThinkingSphinx::Search::StaleIdsException => error
      raise error if @retries <= 0

      append_stale_ids error.ids, error.context
      ThinkingSphinx::Logger.log :message, log_message

      @retries -= 1 and retry
    end
  end

  private

  def append_stale_ids(ids, context)
    @stale_ids |= ids

    context.search.options[:without_ids] ||= []
    context.search.options[:without_ids] |= ids
  end

  def log_message
    'Stale Ids (%s %s left): %s' % [
      @retries, (@retries == 1 ? 'try' : 'tries'), @stale_ids.join(', ')
    ]
  end

  def stale_retries
    case context.search.options[:retry_stale]
    when nil, TrueClass
      2
    when FalseClass
      0
    else
      context.search.options[:retry_stale].to_i
    end
  end
end
