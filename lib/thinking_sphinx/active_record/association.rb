# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::Association
  def initialize(column)
    @column = column
  end

  def stack
    @column.__stack + [@column.__name]
  end

  def string?
    @column.is_a?(String)
  end

  def to_s
    @column.to_s
  end
end
