class ThinkingSphinx::ActiveRecord::Field <
  ThinkingSphinx::ActiveRecord::Property

  def to_select_sql(associations, source)
    "#{column_with_table(associations)} AS #{name}"
  end

  def with_attribute?
    @options[:sortable]
  end
end
