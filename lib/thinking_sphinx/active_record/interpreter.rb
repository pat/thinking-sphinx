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
    columns.each do |column|
      __source.attributes << ThinkingSphinx::ActiveRecord::Attribute.new(column)
    end
  end

  def indexes(*columns)
    columns.each do |column|
      __source.fields << ThinkingSphinx::ActiveRecord::Field.new(column)
    end
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
