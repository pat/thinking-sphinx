# frozen_string_literal: true

class ThinkingSphinx::Configuration::MinimumFields
  def initialize(indices)
    @indices = indices
  end

  def reconcile
    field_collections.each do |collection|
      collection.fields.delete_if do |field|
        field.name == 'sphinx_internal_class_name'
      end
    end
  end

  private

  attr_reader :indices

  def field_collections
    indices_without_inheritance_of_type('plain').collect(&:sources).flatten +
      indices_without_inheritance_of_type('rt')
  end

  def inheritance_columns?(index)
    index.model.table_exists? && index.model.column_names.include?(index.model.inheritance_column)
  end

  def indices_without_inheritance_of_type(type)
    indices_without_inheritance.select { |index| index.type == type }
  end

  def indices_without_inheritance
    indices.reject(&method(:inheritance_columns?))
  end
end
