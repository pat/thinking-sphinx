class ThinkingSphinx::FloatFormatter
  PATTERN = /(\d+)e\-(\d+)$/

  def initialize(float)
    @float = float
  end

  def fixed
    return float.to_s unless exponent_present?

    ("%0.#{decimal_places}f" % float).gsub(/0+$/, '')
  end

  private

  attr_reader :float

  def exponent_decimal_places
    float.to_s[PATTERN, 1].length
  end

  def exponent_factor
    float.to_s[PATTERN, 2].to_i
  end

  def exponent_present?
    float.to_s['e']
  end

  def decimal_places
    exponent_factor + exponent_decimal_places
  end
end
