class ThinkingSphinx::ActiveRecord::SQLSource::Template
  attr_reader :source

  def initialize(source)
    @source = source
  end

  def apply
    add_field class_column, :sphinx_internal_class_name

    add_attribute primary_key,  :sphinx_internal_id,    nil
    add_attribute class_column, :sphinx_internal_class, :string, :facet => true
    add_attribute '0',          :sphinx_deleted,        :integer
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
      adapter = source.adapter
      quoted_column = "#{adapter.quoted_table_name}.#{adapter.quote(model.inheritance_column)}"
      source.adapter.convert_blank quoted_column, "'#{model.sti_name}'"
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

  def primary_key
    source.model.primary_key.to_sym
  end
end
