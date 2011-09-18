class ThinkingSphinx::ActiveRecord::PropertySQLPresenter
  attr_reader :property, :adapter, :associations, :type

  def initialize(property, adapter, associations, type = nil)
    @property, @adapter, @associations, @type =
      property, adapter, associations, type
  end

  def to_group
    return nil unless group?

    column_with_table
  end

  def to_select
    "#{casted_column_with_table} AS #{property.name}"
  end

  private

  def aggregate?
    associations.aggregate_for?(property.column.__stack)
  end

  def casted_column_with_table
    clause = column_with_table
    clause = adapter.cast_to_timestamp(clause) if type == :timestamp
    clause = adapter.group_concatenate(clause, ' ') if aggregate?

    clause
  end

  def column_with_table
    return property.column.__name if property.column.string?

    "#{associations.alias_for(property.column.__stack)}.#{property.column.__name}"
  end

  def group?
    !(aggregate? || property.column.string?)
  end
end
