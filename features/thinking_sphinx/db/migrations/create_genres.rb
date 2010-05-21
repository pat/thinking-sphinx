ActiveRecord::Base.connection.create_table :genres, :force => true do |t|
  t.column :name, :string
end
