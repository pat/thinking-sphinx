# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::Callbacks::UpdateCallbacks <
  ThinkingSphinx::Callbacks

  if ActiveRecord::Base.instance_methods.grep(/saved_changes/).any?
    CHANGED_ATTRIBUTES = lambda { |instance| instance.saved_changes.keys }
  else
    CHANGED_ATTRIBUTES = lambda { |instance| instance.changed }
  end

  callbacks :after_update

  def after_update
    return unless !ThinkingSphinx::Callbacks.suspended? && updates_enabled?

    indices.each do |index|
      update index unless index.distributed?
    end
  end

  private

  def attributes_hash_for(index)
    updateable_attributes_for(index).inject({}) do |hash, attribute|
      if changed_attributes.include?(attribute.columns.first.__name.to_s)
        hash[attribute.name] = attribute.value_for(instance)
      end

      hash
    end
  end

  def changed_attributes
    @changed_attributes ||= CHANGED_ATTRIBUTES.call instance
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
    configuration.index_set_class.reference_name(instance.class)
  end

  def update(index)
    attributes = attributes_hash_for(index)
    return if attributes.empty?

    sphinxql = Riddle::Query.update(
      index.name,
      index.document_id_for_key(instance.public_send(index.primary_key)),
      attributes
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
