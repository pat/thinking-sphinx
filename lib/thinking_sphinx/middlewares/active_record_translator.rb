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
      hash[name] = name.constantize.where(:id => ids)

      stale_ids  = ids - hash[name].collect(&:id)
      if stale_ids.any?
        raise ThinkingSphinx::Search::StaleIdsException, stale_ids
      end

      hash
    }
  end
end
