class ThinkingSphinx::ActiveRecord::Property
  attr_reader :columns, :options

  def initialize(model, columns, options = {})
    @model, @options = model, options

    @columns = Array(columns).collect { |column|
      column.respond_to?(:__name) ? column :
        ThinkingSphinx::ActiveRecord::Column.new(column)
    }
  end

  def facet?
    options[:facet]
  end

  def multi?
    false
  end

  def name
    (options[:as] || columns.first.__name).to_s
  end

  def source_type
    options[:source]
  end

  def type
    nil
  end
end
