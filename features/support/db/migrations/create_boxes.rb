ActiveRecord::Base.connection.create_table :boxes, :force => true do |t|
  t.column :width,  :integer, :null => false
  t.column :length, :integer, :null => false
  t.column :depth,  :integer
end
