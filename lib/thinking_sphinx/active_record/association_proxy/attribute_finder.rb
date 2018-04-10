# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::AssociationProxy::AttributeFinder
  def initialize(association)
    @association = association
  end

  def attribute
    attributes.detect { |attribute|
      ThinkingSphinx::ActiveRecord::AssociationProxy::AttributeMatcher.new(
        attribute, foreign_key
      ).matches?
    } or raise "Missing Attribute for Foreign Key #{foreign_key}"
  end

  private

  def attributes
    indices.collect(&:attributes).flatten
  end

  def configuration
    ThinkingSphinx::Configuration.instance
  end

  def foreign_key
    @foreign_key ||= reflection_target.foreign_key
  end

  def indices
    @indices ||= begin
      configuration.preload_indices
      configuration.indices_for_references(
        *ThinkingSphinx::IndexSet.reference_name(@association.klass)
      ).reject &:distributed?
    end
  end

  def reflection_target
    target = @association.reflection
    target = target.through_reflection if target.through_reflection
    target
  end
end
