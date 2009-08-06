ActiveRecord::Base.connection.create_table :authors, :force => true do |t|
  t.column :name, :string, :null => false
end
