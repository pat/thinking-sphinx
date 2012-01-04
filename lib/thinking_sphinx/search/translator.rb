class ThinkingSphinx::Search::Translator
  attr_reader :raw

  def initialize(raw)
    @raw = raw
  end

  def to_active_record
    results_for_models # load now to avoid segfaults
    raw.collect { |row| ThinkingSphinx::Search::Glaze.new result_for(row) }
  end

  private

  def ids_for_model(model_name)
    raw.select { |row|
      row['sphinx_internal_class'] == model_name
    }.collect { |row|
      row['sphinx_internal_id']
    }
  end

  def model_names
    @model_names ||= raw.collect { |row|
      row['sphinx_internal_class']
    }.uniq
  end

  def result_for(row)
    results_for_models[row['sphinx_internal_class']].detect { |record|
      record.id == row['sphinx_internal_id']
    }
  end

  def results_for_models
    @results_for_models ||= model_names.inject({}) { |hash, name|
      ids = ids_for_model(name)
      hash[name] = name.constantize.where(:id => ids)

      stale_ids = ids - hash[name].collect(&:id)
      if stale_ids.any?
        raise ThinkingSphinx::Search::StaleIdsException, stale_ids
      end

      hash
    }
  end
end
