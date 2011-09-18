class ThinkingSphinx::ActiveRecord::Property
  attr_reader :column

  def initialize(column, options = {})
    @column, @options = column, options
  end

  def name
    (@options[:as] || column.__name).to_s
  end
end
