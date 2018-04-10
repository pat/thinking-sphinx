# frozen_string_literal: true

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
    column_presenters.any? &:aggregate?
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

  def column_presenters
    @column_presenters ||= property.columns.collect { |column|
      ThinkingSphinx::ActiveRecord::ColumnSQLPresenter.new(
        property.model, column, adapter, associations
      )
    }
  end

  def columns_with_table
    column_presenters.collect(&:with_table).compact.join(', ')
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
