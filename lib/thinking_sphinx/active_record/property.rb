class ThinkingSphinx::ActiveRecord::Property
  attr_reader :columns

  def initialize(columns, options = {})
    @columns, @options = Array(columns), options
  end

  def name
    (@options[:as] || columns.first.__name).to_s
  end
end
