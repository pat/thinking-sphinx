class ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter
  def initialize(model)
    @model = model
  end

  def quote(column)
    @model.connection.quote_column_name(column)
  end
end
