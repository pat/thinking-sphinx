class ThinkingSphinx::ActiveRecord::SQLSource::Template
  attr_reader :source

  def initialize(source)
    @source = source
  end

  def apply
    add_field class_column, :sphinx_internal_class, :facet => true

    add_attribute :id, :sphinx_internal_id, nil
    add_attribute '0', :sphinx_deleted,     :integer
  end

  private

  def add_attribute(column, name, type, options = {})
    source.attributes << ThinkingSphinx::ActiveRecord::Attribute.new(
      source.model, ThinkingSphinx::ActiveRecord::Column.new(column),
      options.merge(:as => name, :type => type)
    )
  end

  def add_field(column, name, options = {})
    source.fields << ThinkingSphinx::ActiveRecord::Field.new(
      source.model, ThinkingSphinx::ActiveRecord::Column.new(column),
      options.merge(:as => name)
    )
  end

  def class_column
    if inheriting?
      source.adapter.convert_nulls model.inheritance_column, "'#{model.name}'"
    else
      "'#{model.name}'"
    end
  end

  def inheriting?
    model.column_names.include?(model.inheritance_column)
  end

  def model
    source.model
  end
end
