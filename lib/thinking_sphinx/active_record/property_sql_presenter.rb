class ThinkingSphinx::ActiveRecord::PropertySQLPresenter
  attr_reader :property, :adapter, :associations, :type

  def initialize(property, adapter, associations, type = nil)
    @property, @adapter, @associations, @type =
      property, adapter, associations, type
  end

  def to_group
    return nil unless group?

    columns_with_table
  end

  def to_select
    "#{casted_column_with_table} AS #{adapter.quote property.name}"
  end

  private

  def aggregate?
    property.columns.any? { |column|
      associations.aggregate_for?(column.__stack)
    }
  end

  def casted_column_with_table
    clause = columns_with_table
    clause = adapter.cast_to_timestamp(clause)      if type && type.timestamp?
    clause = adapter.concatenate(clause, ' ')       if concatenating?
    clause = adapter.group_concatenate(clause, ' ') if aggregate?

    clause
  end

  def column_with_table(column)
    return column.__name if column.string?

    "#{associations.alias_for(column.__stack)}.#{adapter.quote column.__name}"
  end

  def columns_with_table
    property.columns.collect { |column|
      column_with_table(column)
    }.join(', ')
  end

  def concatenating?
    property.columns.length > 1
  end

  def group?
    !(aggregate? || property.columns.any?(&:string?))
  end
end
