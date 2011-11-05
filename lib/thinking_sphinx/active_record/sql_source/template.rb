class ThinkingSphinx::ActiveRecord::SQLSource::Template
  attr_reader :source

  def initialize(source)
    @source = source
  end

  def apply
    add_field     class_column, :sphinx_class

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

  def class_column
    inheritance_column? ? model.inheritance_column.to_sym : "'#{model.name}'"
  end

  def inheritance_column?
    model.column_names.include?(model.inheritance_column)
  end

  def model
    source.model
  end
end
