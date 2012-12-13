class ThinkingSphinx::ActiveRecord::Interpreter <
  ::ThinkingSphinx::Core::Interpreter

  def define_source(&block)
    @source = @index.append_source
    instance_eval &block
  end

  def group_by(*columns)
    __source.groupings += columns
  end

  def has(*columns)
    __source.attributes += build_properties(
      ::ThinkingSphinx::ActiveRecord::Attribute, columns
    )
  end

  def indexes(*columns)
    __source.fields += build_properties(
      ::ThinkingSphinx::ActiveRecord::Field, columns
    )
  end

  def join(*columns)
    __source.associations += columns.collect { |column|
      ::ThinkingSphinx::ActiveRecord::Association.new column
    }
  end

  def sanitize_sql(*arguments)
    __source.model.send :sanitize_sql, *arguments
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

  def build_properties(klass, columns)
    options = columns.extract_options!
    columns.collect { |column| klass.new(__source.model, column, options) }
  end
end
