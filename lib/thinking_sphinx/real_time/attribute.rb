class ThinkingSphinx::RealTime::Attribute
  def initialize(column, options = {})
    @column, @options = column, options
  end

  def name
    (@options[:as] || @column.__name).to_s
  end

  def translate(object)
    return @column.__name unless @column.__name.is_a?(Symbol)

    base = object
    @column.__stack.each { |node| base = base.try(node) }
    base.send(@column.__name)
  end

  def type
    @options[:type]
  end
end
