class ThinkingSphinx::ActiveRecord::Property
  attr_reader :column

  def initialize(column, options = {})
    @column, @options = column, options
  end

  def name
    (@options[:as] || column.__name).to_s
  end

  def to_group_sql(associations)
    column.string? ? nil : column_with_table(associations)
  end

  private

  def column_with_table(associations)
    return column.__name if column.string?

    "#{associations.alias_for(column.__stack)}.#{column.__name}"
  end
end
