class ThinkingSphinx::Middlewares::ActiveRecordTranslator <
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
      results_for_models # load now to avoid segfaults
      context[:results] = context[:results].collect { |row| result_for row }
    end

    private

    attr_reader :context

    def ids_for_model(model_name)
      context[:results].select { |row|
        row['sphinx_internal_class'] == model_name
      }.collect { |row|
        row['sphinx_internal_id']
      }
    end

    def model_names
      @model_names ||= context[:results].collect { |row|
        row['sphinx_internal_class']
      }.uniq
    end

    def reset_memos
      @model_names        = nil
      @results_for_models = nil
    end

    def result_for(row)
      results_for_models[row['sphinx_internal_class']].detect { |record|
        record.id == row['sphinx_internal_id']
      }
    end

    def results_for_models
      @results_for_models ||= model_names.inject({}) { |hash, name|
        ids      = ids_for_model(name)
        model    = name.constantize
        relation = model.unscoped

        relation = relation.includes sql_options[:include] if sql_options[:include]
        relation = relation.joins  sql_options[:joins]  if sql_options[:joins]
        relation = relation.order  sql_options[:order]  if sql_options[:order]
        relation = relation.select sql_options[:select] if sql_options[:select]

        hash[name] = relation.where(model.primary_key => ids)

        hash
      }
    end

    def sql_options
      context.search.options[:sql] || {}
    end
  end
end
