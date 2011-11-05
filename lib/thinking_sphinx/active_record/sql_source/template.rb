class ThinkingSphinx::ActiveRecord::SQLSource::Template
  attr_reader :source

  def initialize(source)
    @source = source
  end

  def apply
    add_field     class_column("'thinkingsphinxbase'"), :sphinx_class

    add_attribute :id,          :sphinx_internal_id,    :integer
    add_attribute class_column, :sphinx_internal_class, :string
    add_attribute '0',          :sphinx_deleted,        :boolean
  end

  private

  def add_attribute(column, name, type)
    source.attributes << ThinkingSphinx::ActiveRecord::Attribute.new(
      ThinkingSphinx::ActiveRecord::Column.new(column),
      :as => name, :type => type
    )
  end

  def add_field(column, name)
    source.fields << ThinkingSphinx::ActiveRecord::Field.new(
      ThinkingSphinx::ActiveRecord::Column.new(column), :as => name
    )
  end

  def class_column(prefix = '')
    column = "'#{model.name}'"
    if inheritance_column?
      column = source.adapter.convert_nulls model.inheritance_column, column
        "'#{model.name}'"
      column = source.adapter.concatenate [prefix, column].join(', ') unless prefix.empty?
    end

    column
  end

  def inheritance_column?
    model.column_names.include?(model.inheritance_column)
  end

  def model
    source.model
  end
end
