# frozen_string_literal: true

ThinkingSphinx::Index.define :colour, :with => :active_record, :delta => true do
  indexes name

  has tees.id, :as => :tee_ids
end
