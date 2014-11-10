class ThinkingSphinx::RealTime::Index::Template
  attr_reader :index

  def initialize(index)
    @index = index
  end

  def apply
    add_field class_column, :sphinx_internal_class_name

    add_attribute :id,          :sphinx_internal_id,    :bigint
    add_attribute class_column, :sphinx_internal_class, :string, :facet => true
    add_attribute 0,            :sphinx_deleted,        :integer
  end

  private

  def add_attribute(column, name, type, options = {})
    index.add_attribute ThinkingSphinx::RealTime::Attribute.new(
      ThinkingSphinx::ActiveRecord::Column.new(*column),
      options.merge(:as => name, :type => type)
    )
  end

  def add_field(column, name)
    index.add_field ThinkingSphinx::RealTime::Field.new(
      ThinkingSphinx::ActiveRecord::Column.new(*column), :as => name
    )
  end

  def class_column
    [:class, :name]
  end
end
