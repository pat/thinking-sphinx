class ThinkingSphinx::ActiveRecord::DatabaseAdapters::AbstractAdapter
  def initialize(model)
    @model = model
  end
end
