ThinkingSphinx::Index.define :article, :with => :active_record do
  indexes title, content
  indexes user.name, :as => :user
  indexes user.articles.title, :as => :related_titles

  has published

  set_property :min_infix_len => 4
  set_property :enable_star   => true
end
