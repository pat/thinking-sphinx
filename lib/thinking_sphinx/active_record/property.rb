class ThinkingSphinx::ActiveRecord::Property
  include ThinkingSphinx::Core::Property

  attr_reader :model, :columns, :options

  def initialize(model, columns, options = {})
    @model, @options = model, options

    @columns = Array(columns).collect { |column|
      column.respond_to?(:__name) ? column :
        ThinkingSphinx::ActiveRecord::Column.new(column)
    }
  end

  def rebase(associations, options)
    @columns = columns.inject([]) do |array, column|
      array + column.__replace(associations, options[:to])
    end
  end

  def name
    (options[:as] || columns.first.__name).to_s
  end

  def source_type
    options[:source]
  end
end
