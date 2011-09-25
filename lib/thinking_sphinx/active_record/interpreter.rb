class ThinkingSphinx::ActiveRecord::Interpreter < BlankSlate
  def self.translate!(index, block)
    new(index, block).translate!
  end

  def initialize(index, block)
    @index = index

    mod = Module.new
    mod.send :define_method, :translate!, block
    extend mod
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

  private

  def method_missing(method, *args)
    ThinkingSphinx::ActiveRecord::Column.new method, *args
  end

  def __source
    @source ||= begin
      ThinkingSphinx::ActiveRecord::SQLSource.new(
        @index.model, :offset => @index.offset
      ).tap do |source|
        @index.sources << source
      end
    end
  end
end
