class ThinkingSphinx::ActiveRecord::PropertySQLPresenter
  attr_reader :property, :adapter, :associations

  def initialize(property, adapter, associations)
    @property, @adapter, @associations = property, adapter, associations
  end

  def to_group
    return nil if sourced_by_query? || !group?

    columns_with_table
  end

  def to_select
    return nil if sourced_by_query?

    "#{casted_column_with_table} AS #{adapter.quote property.name}"
  end

  private

  delegate :multi?, :to => :property

  def aggregate?
    property.columns.any? { |column|
      Joiner::Path.new(property.model, column.__stack).aggregate?
    }
  end

  def aggregate_separator
    multi? ? ',' : ' '
  end

  def cast_to_timestamp(clause)
    return adapter.cast_to_timestamp clause if property.columns.any?(&:string?)

    clause.split(', ').collect { |part|
      adapter.cast_to_timestamp part
    }.join(', ')
  end

  def casted_column_with_table
    clause = columns_with_table
    clause = cast_to_timestamp clause if property.type == :timestamp
    clause = concatenate clause
    if aggregate?
      clause = adapter.group_concatenate(clause, aggregate_separator)
    end

    clause
  end

  def column_exists?(column)
    model = Joiner::Path.new(property.model, column.__stack).model
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

  def sourced_by_query?
    property.source_type.to_s[/query/]
  end
end
