ThinkingSphinx::Index.define :book, :with => :active_record, :delta => true do
  indexes title, :sortable => true
  indexes author
  indexes [title, author], :as => :info

  has year, created_at
end
