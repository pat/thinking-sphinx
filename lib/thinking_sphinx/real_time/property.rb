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
    ThinkingSphinx::RealTime::Translator.call(object, @column)
  end
end
