class ThinkingSphinx::ActiveRecord::Property
  attr_reader :columns, :options

  def initialize(model, columns, options = {})
    @model, @columns, @options = model, Array(columns), options
  end

  def multi?
    false
  end

  def name
    (options[:as] || columns.first.__name).to_s
  end

  def type
    nil
  end
end
