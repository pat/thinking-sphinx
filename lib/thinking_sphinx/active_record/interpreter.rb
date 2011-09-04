class ThinkingSphinx::ActiveRecord::Interpreter < BlankSlate
  def self.translate!(index, block)
    new(index, block).translate!
  end

  def initialize(index, block)
    @index, @block = index, block
  end

  def indexes(*columns)
    columns.each do |column|
      __source.fields << ThinkingSphinx::ActiveRecord::Field.new(column)
    end
  end

  def translate!
    instance_eval &@block
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
