class ThinkingSphinx::Middlewares::ActiveRecordTranslator <
  ThinkingSphinx::Middlewares::Middleware

  def call(context)
    @context = context
    reset_memos

    results_for_models # load now to avoid segfaults
    context[:results] = context[:results].collect { |row| result_for row }

    app.call context
  end

  private

  def ids_for_model(model_name)
    context[:results].select { |row|
      row['sphinx_internal_class_attr'] == model_name
    }.collect { |row|
      row['sphinx_internal_id']
    }
  end

  def model_names
    @model_names ||= context[:results].collect { |row|
      row['sphinx_internal_class_attr']
    }.uniq
  end

  def reset_memos
    @model_names        = nil
    @results_for_models = nil
  end

  def result_for(row)
    results_for_models[row['sphinx_internal_class_attr']].detect { |record|
      record.id == row['sphinx_internal_id']
    }
  end

  def results_for_models
    @results_for_models ||= model_names.inject({}) { |hash, name|
      ids        = ids_for_model(name)
      relation   = name.constantize.unscoped

      relation = relation.includes sql_options[:include] if sql_options[:include]
      relation = relation.joins  sql_options[:joins]  if sql_options[:joins]
      relation = relation.order  sql_options[:order]  if sql_options[:order]
      relation = relation.select sql_options[:select] if sql_options[:select]

      hash[name] = relation.where(:id => ids)

      hash
    }
  end

  def sql_options
    context.search.options[:sql] || {}
  end
end
