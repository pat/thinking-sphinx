# frozen_string_literal: true

ThinkingSphinx::Index.define :city, :with => :active_record do
  indexes name
  has lat, lng

  set_property :charset_table => '0..9, A..Z->a..z, _, a..z, U+410..U+42F->U+430..U+44F, U+430..U+44F, U+0130'
  set_property :utf8? => true
end
