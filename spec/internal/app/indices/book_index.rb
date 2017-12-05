# frozen_string_literal: true

ThinkingSphinx::Index.define :book, :with => :active_record, :delta => true do
  indexes title, :sortable => true
  indexes author, :facet => true
  indexes [title, author], :as => :info
  indexes blurb_file, :file => true

  has year
  has created_at, :type => :timestamp
end
