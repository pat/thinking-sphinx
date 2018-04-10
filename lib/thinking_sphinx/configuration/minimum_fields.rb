# frozen_string_literal: true

class ThinkingSphinx::Configuration::MinimumFields
  def initialize(indices)
    @indices = indices
  end

  def reconcile
    return unless no_inheritance_columns?

    field_collections.each do |collection|
      collection.fields.delete_if do |field|
        field.name == 'sphinx_internal_class_name'
      end
    end
  end

  private

  attr_reader :indices

  def field_collections
    indices_of_type('plain').collect(&:sources).flatten +
    indices_of_type('rt')
  end

  def indices_of_type(type)
    indices.select { |index| index.type == type }
  end

  def no_inheritance_columns?
    indices.select { |index|
      index.model.table_exists? &&
      index.model.column_names.include?(index.model.inheritance_column)
    }.empty?
  end
end
