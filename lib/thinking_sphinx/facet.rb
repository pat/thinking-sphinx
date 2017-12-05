# frozen_string_literal: true

class ThinkingSphinx::Facet
  attr_reader :name

  def initialize(name, properties)
    @name, @properties = name, properties
  end

  def filter_type
    use_field? ? :conditions : :with
  end

  def results_from(raw)
    raw.inject({}) { |hash, row|
      hash[row[group_column]] = row[ThinkingSphinx::SphinxQL.count[:column]]
      hash
    }
  end

  private

  def group_column
    @properties.any?(&:multi?) ?
      ThinkingSphinx::SphinxQL.group_by[:column] : name
  end

  def use_field?
    @properties.any? { |property|
      property.type.nil? || property.type == :string
    }
  end
end
