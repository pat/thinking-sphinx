# frozen_string_literal: true

ThinkingSphinx::Index.define :animal, :with => :active_record do
  indexes name
end
