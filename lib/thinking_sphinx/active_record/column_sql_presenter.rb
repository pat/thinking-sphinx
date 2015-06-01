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

    quoted_table = escape_table? ? adapter.quote(table) : table

    "#{quoted_table}.#{adapter.quote __name}"
  end

  private

  attr_reader :model, :column, :adapter, :associations

  delegate :__stack, :__name, :string?, :to => :column

  def escape_table?
    table[/[`"]/].nil?
  end

  def exists?
    path.model.column_names.include?(column.__name.to_s)
  rescue Joiner::AssociationNotFound
    false
  end

  def path
    Joiner::Path.new model, column.__stack
  end

  def table
    associations.alias_for __stack
  end

  def version
    ActiveRecord::VERSION
  end
end
