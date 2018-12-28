# frozen_string_literal: true

ThinkingSphinx::Index.define :album, :with => :active_record, :primary_key => :integer_id, :delta => true do
  indexes name, artist
end

ThinkingSphinx::Index.define :album, :with => :real_time, :primary_key => :integer_id, :name => :album_real do
  indexes name, artist
end
