ActiveRecord::Base.connection.create_table :music, :force => true do |t|
  t.column :artist,   :string
  t.column :album,    :string
  t.column :track,    :string
  t.column :genre_id, :integer
end
