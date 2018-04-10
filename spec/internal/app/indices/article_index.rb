# frozen_string_literal: true

ThinkingSphinx::Index.define :article, :with => :active_record do
  indexes title, content
  indexes user.name, :as => :user
  indexes user.articles.title, :as => :related_titles

  has published, user_id
  has taggings.tag_id, :as => :tag_ids, :source => :query
  has taggings.created_at, :as => :taggings_at, :type => :timestamp

  set_property :min_infix_len => 4
  set_property :enable_star   => true
end

ThinkingSphinx::Index.define :article, :with => :active_record,
  :name => 'stemmed_article' do

  indexes title

  has published, user_id
  has taggings.tag_id, :as => :tag_ids
  has taggings.created_at, :as => :taggings_at, :type => :timestamp

  set_property :morphology => 'stem_en'
end
