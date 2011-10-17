ThinkingSphinx::Index.define :city, :with => :active_record do
  indexes name
  has lat, lng
end
