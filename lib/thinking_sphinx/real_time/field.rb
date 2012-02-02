class ThinkingSphinx::RealTime::Field
  def initialize(column, options = {})
    @column, @options = column, options
  end

  def name
    (@options[:as] || @column.__name).to_s
  end

  def translate(object)
    base = object
    @column.__stack.each { |node| base = base.try(node) }
    base.send(@column.__name)
  end
end
