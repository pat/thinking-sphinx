ThinkingSphinx::Index.define :car, :with => :real_time do
  indexes name, :sortable => true

  has manufacturer_id, :type => :integer
end
