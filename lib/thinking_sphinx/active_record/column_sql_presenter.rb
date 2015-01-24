class ThinkingSphinx::ActiveRecord::ColumnSQLPresenter
  def initialize(model, column, adapter, associations)
    @model, @column, @adapter, @associations = model, column, adapter, associations
  end

  def aggregate?
    path.aggregate?
  rescue Joiner::AssociationNotFound
    false
  end

  def with_table
    return __name if string?
    return nil unless exists?

    "#{adapter.quote associations.alias_for(__stack)}.#{adapter.quote __name}"
  end

  private

  attr_reader :model, :column, :adapter, :associations

  delegate :__stack, :__name, :string?, :to => :column

  def exists?
    path.model.column_names.include?(column.__name.to_s)
  rescue Joiner::AssociationNotFound
    false
  end

  def path
    Joiner::Path.new model, column.__stack
  end
end
