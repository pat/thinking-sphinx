class ThinkingSphinx::Middlewares::IdsOnly <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    contexts.each do |context|
      context[:results] = context[:results].collect { |row|
        row['sphinx_internal_id']
      }
    end

    app.call contexts
  end
end
