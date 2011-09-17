ThinkingSphinx::Index.define :article, :with => :active_record do
  indexes title, content
  indexes user.name, :as => :user

  has published
end
