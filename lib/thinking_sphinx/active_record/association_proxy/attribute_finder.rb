class ThinkingSphinx::ActiveRecord::AssociationProxy::AttributeFinder
  def initialize(association)
    @association = association
  end

  def attribute
    attributes.detect { |attribute|
      columns = attribute.respond_to?(:columns) ? attribute.columns : [ attribute.column ]

      # Don't bother with attributes built from multiple columns
      next if columns.many?

      columns.first.__name == foreign_key.to_sym ||
      attribute.name == foreign_key.to_s ||
      (attribute.multi? && attribute.name.singularize == foreign_key.to_s)
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
      ).reject &:distributed?
    end
  end

  def reflection_target
    target = @association.reflection
    target = target.through_reflection if target.through_reflection
    target
  end

  def sources
    indices.collect { |index| index.respond_to?(:sources) ? index.sources : index }.flatten
  end
end
