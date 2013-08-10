class ThinkingSphinx::RealTime::Interpreter <
  ::ThinkingSphinx::Core::Interpreter

  def has(*columns)
    options = columns.extract_options!
    @index.attributes += columns.collect { |column|
      ::ThinkingSphinx::RealTime::Attribute.new column, options
    }
  end

  def indexes(*columns)
    options = columns.extract_options!
    @index.fields += columns.collect { |column|
      ::ThinkingSphinx::RealTime::Field.new column, options
    }
  end

  def scope(&block)
    @index.scope = block
  end

  def set_property(properties)
    properties.each do |key, value|
      @index.send("#{key}=", value)   if @index.class.settings.include?(key)
    end
  end

  def where(condition)
    @index.conditions << condition
  end
end
