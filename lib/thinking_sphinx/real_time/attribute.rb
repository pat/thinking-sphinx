class ThinkingSphinx::RealTime::Attribute < ThinkingSphinx::RealTime::Property
  def multi?
    @options[:multi]
  end

  def type
    @options[:type]
  end

  def translate(object)
    output = super || default_value

    json? ? output.to_json : output
  end

  private

  def default_value
    type == :string ? '' : 0
  end

  def json?
    type == :json
  end
end
