ThinkingSphinx::Index.define :book, :with => :active_record do
  indexes title, :sortable => true
  indexes author

  has year
end
