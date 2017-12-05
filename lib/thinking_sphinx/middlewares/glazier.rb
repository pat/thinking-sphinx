# frozen_string_literal: true

class ThinkingSphinx::Middlewares::Glazier <
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
      return if context[:panes].empty?

      context[:results] = context[:results].collect { |result|
        ThinkingSphinx::Search::Glaze.new context, result, row_for(result),
          context[:panes]
      }
    end

    private

    attr_reader :context

    def row_for(result)
      context[:raw].detect { |row|
        row['sphinx_internal_class'] == result.class.name &&
        row['sphinx_internal_id']    == result.id
      }
    end
  end
end
