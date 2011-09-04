class ThinkingSphinx::ActiveRecord::Field
  attr_reader :column

  def initialize(column)
    @column = column
  end

  def to_group_sql
    column.__name.to_s
  end

  def to_select_sql
    column.__name.to_s
  end
end
