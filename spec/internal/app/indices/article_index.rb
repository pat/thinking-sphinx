ThinkingSphinx::Index.define :article, :with => :active_record do
  indexes title, content
  indexes user.name, :as => :user
  indexes user.articles.title, :as => :related_titles

  has published
end
