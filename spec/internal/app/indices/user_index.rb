# frozen_string_literal: true

ThinkingSphinx::Index.define :user, :with => :active_record do
  indexes name

  has articles.taggings.tag_id, :as => :tag_ids, :facet => true

  set_property :big_document_ids => true
end
