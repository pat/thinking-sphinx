class ThinkingSphinx::ActiveRecord::PropertySQLPresenter
  attr_reader :property, :adapter, :associations

  def initialize(property, adapter, associations)
    @property, @adapter, @associations = property, adapter, associations
  end

  def to_group
    return nil unless group?

    columns_with_table
  end

  def to_select
    return nil if property.source_type.to_s[/query/]

    "#{casted_column_with_table} AS #{adapter.quote property.name}"
  end

  private

  def aggregate?
    property.columns.any? { |column|
      associations.aggregate_for?(column.__stack)
    }
  end

  def aggregate_separator
    (property.multi?) ? ',' : ' '
  end

  def casted_column_with_table
    clause = columns_with_table
    clause = adapter.cast_to_timestamp(clause) if property.type == :timestamp
    clause = concatenate clause
    if aggregate?
      clause = adapter.group_concatenate(clause, aggregate_separator)
    end

    clause
  end

  def column_exists?(column)
    model = associations.model_for(column.__stack)
    model && model.column_names.include?(column.__name.to_s)
  end

  def column_with_table(column)
    return column.__name if column.string?
    return nil unless column_exists?(column)

    "#{associations.alias_for(column.__stack)}.#{adapter.quote column.__name}"
  end

  def columns_with_table
    property.columns.collect { |column|
      column_with_table(column)
    }.compact.join(', ')
  end

  def concatenating?
    property.columns.length > 1
  end

  def concatenate(clause)
    return clause unless concatenating?

    if property.type.nil?
      adapter.concatenate clause, ' '
    else
      clause = clause.split(', ').collect { |part|
        adapter.cast_to_string part
      }.join(', ')
      adapter.concatenate clause, ','
    end
  end

  def group?
    !(aggregate? || property.columns.any?(&:string?))
  end
end
