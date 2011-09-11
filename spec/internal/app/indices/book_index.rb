ThinkingSphinx::Index.define :book, :with => :active_record do
  indexes title, author
end
