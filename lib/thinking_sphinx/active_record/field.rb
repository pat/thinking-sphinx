class ThinkingSphinx::ActiveRecord::Field <
  ThinkingSphinx::ActiveRecord::Property

  def file?
    options[:file]
  end

  def with_attribute?
    options[:sortable] || options[:facet]
  end
end
