ThinkingSphinx::Index.define :product, :with => :real_time do
  indexes name, :sortable => true

  has category_ids, :type => :integer, :multi => true
end
