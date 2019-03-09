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
      @indices = {}
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

    def indices_for(model)
      @indices[model] ||= context[:indices].select do |index|
        index.model == model
      end
    end

    def row_for(result)
      ids = indices_for(result.class).collect do |index|
        result.send index.primary_key
      end

      context[:raw].detect { |row|
        row['sphinx_internal_class'] == result.class.name &&
        ids.include?(row['sphinx_internal_id'])
      }
    end
  end
end
