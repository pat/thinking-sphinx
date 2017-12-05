# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter
  def initialize(model)
    @model = model
  end

  def quote(column)
    @model.connection.quote_column_name(column)
  end

  def quoted_table_name
    @model.quoted_table_name
  end

  def utf8_query_pre
    []
  end
end
