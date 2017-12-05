# frozen_string_literal: true

class ThinkingSphinx::Middlewares::ValidOptions <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    contexts.each { |context| check_options context.search.options }

    app.call contexts
  end

  private

  def check_options(options)
    unknown = invalid_keys options.keys
    return if unknown.empty?

    ThinkingSphinx::Logger.log :caution,
      "Unexpected search options: #{unknown.inspect}"
  end

  def invalid_keys(keys)
    keys - ThinkingSphinx::Search.valid_options
  end
end
