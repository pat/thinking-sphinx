ThinkingSphinx::Index.define :book, :with => :active_record do
  indexes title, :sortable => true
  indexes author
  indexes [title, author], :as => :info

  has year, created_at
end
