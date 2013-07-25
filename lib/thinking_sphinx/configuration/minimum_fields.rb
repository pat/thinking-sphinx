class ThinkingSphinx::Configuration::MinimumFields
  def initialize(indices)
    @indices = indices
  end

  def reconcile
    return unless no_inheritance_columns?

    sources.each do |source|
      source.fields.delete_if do |field|
        field.name == 'sphinx_internal_class_name'
      end
    end
  end

  private

  attr_reader :indices

  def no_inheritance_columns?
    indices.select { |index|
      index.model.column_names.include?(index.model.inheritance_column)
    }.empty?
  end

  def sources
    @sources ||= @indices.select { |index|
      index.respond_to?(:sources)
    }.collect(&:sources).flatten
  end
end
