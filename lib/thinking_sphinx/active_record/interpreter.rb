class ThinkingSphinx::ActiveRecord::Interpreter < BlankSlate
  reveal :extend if RUBY_DESCRIPTION[/^ruby 1.9/].nil?

  def self.translate!(index, block)
    new(index, block).translate!
  end

  def initialize(index, block)
    @index = index

    mod = Module.new
    mod.send :define_method, :translate!, block
    extend mod
  end

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

  def method_missing(method, *args)
    ThinkingSphinx::ActiveRecord::Column.new method, *args
  end

  def __source
    @source ||= @index.append_source
  end
end
