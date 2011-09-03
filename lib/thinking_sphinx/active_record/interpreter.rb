class ThinkingSphinx::ActiveRecord::Interpreter < BlankSlate
  def self.translate!(index, block)
    new(index, block).translate!
  end

  def initialize(index, block)
    @index, @block = index, block
  end

  def indexes(column)
    __source.fields << ThinkingSphinx::ActiveRecord::Field.new(column)
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
      @index.sources << ThinkingSphinx::ActiveRecord::SQLSource.new(
        @index.model
      )
    end
  end
end
