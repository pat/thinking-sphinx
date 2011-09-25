class ThinkingSphinx::ActiveRecord::Association
  def initialize(column)
    @column = column
  end

  def stack
    @column.__stack + [@column.__name]
  end
end
