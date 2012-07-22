class ThinkingSphinx::Middlewares::StaleIds <
  ThinkingSphinx::Middlewares::Middleware

  def call(context)
    @context   = context
    @stale_ids = []
    @retries   = stale_retries

    begin
      app.call context
    rescue ThinkingSphinx::Search::StaleIdsException => error
      raise error if @retries <= 0

      append_stale_ids error.ids
      log_stale_ids

      @retries -= 1 and retry
    end
  end

  private

  def append_stale_ids(ids)
    @stale_ids |= ids

    context.search.options[:without_ids] ||= []
    context.search.options[:without_ids] |= ids
  end

  def log_stale_ids
    ActiveSupport::Notifications.instrument 'message.thinking_sphinx',
      :message => log_message
  end

  def log_message
    'Stale Ids (%s %s left): %s' % [
      @retries, (@retries == 1 ? 'try' : 'tries'), @stale_ids.join(', ')
    ]
  end

  def stale_retries
    case context.search.options[:retry_stale]
    when nil, TrueClass
      3
    when FalseClass
      0
    else
      context.search.options[:retry_stale].to_i
    end
  end
end
