# frozen_string_literal: true

class ThinkingSphinx::Middlewares::StaleIdChecker <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    contexts.each do |context|
      Inner.new(context).call
    end

    app.call contexts
  end

  private

  class Inner
    def initialize(context)
      @context = context
    end

    def call
      raise_exception if context[:results].any?(&:nil?)
    end

    private

    attr_reader :context

    def actual_ids
      context[:results].compact.collect(&:id)
    end

    def expected_ids
      context[:raw].collect { |row| row['sphinx_internal_id'].to_i }
    end

    def raise_exception
      raise ThinkingSphinx::Search::StaleIdsException.new(stale_ids, context)
    end

    def stale_ids
      # Currently only works with single-model queries. Has at no point done
      # otherwise, but such an improvement would be nice.
      expected_ids - actual_ids
    end
  end
end
