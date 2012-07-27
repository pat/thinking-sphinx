class ThinkingSphinx::Middlewares::StaleIdChecker <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    contexts.each do |context|
      @context = context

      raise_exception if context[:results].any?(&:nil?)
    end

    app.call contexts
  end

  private

  def actual_ids
    context[:results].compact.collect(&:id)
  end

  def expected_ids
    context[:raw].collect { |row| row['sphinx_internal_id'].to_i }
  end

  def raise_exception
    raise ThinkingSphinx::Search::StaleIdsException, stale_ids
  end

  def stale_ids
    # Currently only works with single-model queries. Has at no point done
    # otherwise, but such an improvement would be nice.
    expected_ids - actual_ids
  end
end
