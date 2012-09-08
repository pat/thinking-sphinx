ThinkingSphinx::Index.define :user, :with => :active_record do
  indexes name

  has articles.taggings.tag_id, :as => :tag_ids, :facet => true
end
