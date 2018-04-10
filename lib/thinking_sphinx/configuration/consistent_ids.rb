# frozen_string_literal: true

class ThinkingSphinx::Configuration::ConsistentIds
  def initialize(indices)
    @indices = indices
  end

  def reconcile
    return unless sphinx_internal_ids.any? { |attribute|
      attribute.type == :bigint
    }

    sphinx_internal_ids.each do |attribute|
      attribute.type = :bigint
    end
  end

  private

  def attributes
    @attributes = sources.collect(&:attributes).flatten
  end

  def sphinx_internal_ids
    @sphinx_internal_ids ||= attributes.select { |attribute|
      attribute.name == 'sphinx_internal_id'
    }
  end

  def sources
    @sources ||= @indices.select { |index|
      index.respond_to?(:sources)
    }.collect(&:sources).flatten
  end
end
