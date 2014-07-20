class ThinkingSphinx::ActiveRecord::Callbacks::UpdateCallbacks <
  ThinkingSphinx::Callbacks

  callbacks :after_update

  def after_update
    return unless updates_enabled?

    indices.each do |index|
      update index unless index.distributed?
    end
  end

  private

  def attributes_hash_for(index)
    updateable_attributes_for(index).inject({}) do |hash, attribute|
      if instance.changed.include?(attribute.columns.first.__name.to_s)
        hash[attribute.name] = attribute.value_for(instance)
      end

      hash
    end
  end

  def configuration
    ThinkingSphinx::Configuration.instance
  end

  def indices
    @indices ||= begin
      all = configuration.indices_for_references(reference)
      all.reject { |index| index.type == 'rt' }
    end
  end

  def reference
    instance.class.name.underscore.to_sym
  end

  def update(index)
    attributes = attributes_hash_for(index)
    return if attributes.empty?

    sphinxql = Riddle::Query.update(
      index.name, index.document_id_for_key(instance.id), attributes
    )
    ThinkingSphinx::Connection.take do |connection|
      connection.execute(sphinxql)
    end
  rescue ThinkingSphinx::ConnectionError => error
    # This isn't vital, so don't raise the error.
  end

  def updateable_attributes_for(index)
    index.sources.collect(&:attributes).flatten.select { |attribute|
      attribute.updateable?
    }
  end

  def updates_enabled?
    configuration.settings['attribute_updates']
  end
end
