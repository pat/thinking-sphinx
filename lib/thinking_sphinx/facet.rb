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
      hash[row[group_column]] = row["sphinx_internal_count"]
      hash
    }
  end

  private

  def group_column
    @properties.any?(&:multi?) ? "sphinx_internal_group" : name
  end

  def use_field?
    @properties.any? { |property|
      property.type.nil? || property.type == :string
    }
  end
end
