class ThinkingSphinx::RealTime::Attribute < ThinkingSphinx::RealTime::Property
  def type
    @options[:type]
  end

  def translate(object)
    super || default_value
  end

  private

  def default_value
    type == :string ? '' : 0
  end
end
