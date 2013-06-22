class ThinkingSphinx::ActiveRecord::AssociationProxy::AttributeFinder
  def initialize(association)
    @association = association
  end

  def attribute
    attributes.detect { |attribute|
      # Don't bother with attributes built from multiple columns
      next unless attribute.columns.length == 1

      attribute.columns.first.__name == foreign_key.to_sym ||
      attribute.name == foreign_key.to_s
    } or raise "Missing Attribute for Foreign Key #{foreign_key}"
  end

  private
  def attributes
    sources.collect(&:attributes).flatten
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
        *@association.klass.name.underscore.to_sym
      )
    end
  end

  def reflection_target
    target = @association.reflection
    target = target.through_reflection if target.through_reflection
    target
  end

  def sources
    indices.collect(&:sources).flatten
  end
end
