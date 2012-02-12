class ThinkingSphinx::ActiveRecord::Interpreter <
  ThinkingSphinx::Core::Interpreter

  def group_by(*columns)
    __source.groupings += columns
  end

  def has(*columns)
    options = columns.extract_options!
    __source.attributes += columns.collect { |column|
      ThinkingSphinx::ActiveRecord::Attribute.new column, options
    }
  end

  def indexes(*columns)
    options = columns.extract_options!
    __source.fields += columns.collect { |column|
      ThinkingSphinx::ActiveRecord::Field.new column, options
    }
  end

  def join(*columns)
    __source.associations += columns.collect { |column|
      ThinkingSphinx::ActiveRecord::Association.new column
    }
  end

  def set_property(properties)
    properties.each do |key, value|
      @index.send("#{key}=", value)   if @index.class.settings.include?(key)
      __source.send("#{key}=", value) if __source.class.settings.include?(key)
    end
  end

  def where(*conditions)
    __source.conditions += conditions
  end

  private

  def __source
    @source ||= @index.append_source
  end
end
