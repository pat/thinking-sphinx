class ThinkingSphinx::RealTime::Property
  attr_reader :options

  def initialize(column, options = {})
    @column, @options = column, options
  end

  def name
    (@options[:as] || @column.__name).to_s
  end

  def translate(object)
    return @column.__name unless @column.__name.is_a?(Symbol)

    base = @column.__stack.inject(object) { |base, node| base.try(node) }
    base.try(@column.__name)
  end
end
