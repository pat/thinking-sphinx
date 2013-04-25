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
      hash[row[group_column]] = row['count(*)']
      hash
    }
  end

  private

  def group_column
    @properties.any?(&:multi?) ? '@groupby' : name
  end

  def use_field?
    @properties.any? { |property|
      property.type.nil? || property.type == :string
    }
  end
end
