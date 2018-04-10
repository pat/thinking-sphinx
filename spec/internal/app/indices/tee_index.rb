# frozen_string_literal: true

ThinkingSphinx::Index.define :tee, :with => :active_record do
  index colour.name
  has colour_id, :facet => true
end
