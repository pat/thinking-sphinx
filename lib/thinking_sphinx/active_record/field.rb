class ThinkingSphinx::ActiveRecord::Field <
  ThinkingSphinx::ActiveRecord::Property

  def with_attribute?
    @options[:sortable]
  end
end
