# frozen_string_literal: true

ThinkingSphinx::Index.define :album, :with => :active_record, :primary_key => :integer_id, :delta => true do
  indexes name, artist
end
