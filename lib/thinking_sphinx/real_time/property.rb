class ThinkingSphinx::RealTime::Property
  include ThinkingSphinx::Core::Property

  attr_reader :column, :options

  def initialize(column, options = {})
    @options = options
    @column  = column.respond_to?(:__name) ? column :
      ThinkingSphinx::ActiveRecord::Column.new(column)
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
