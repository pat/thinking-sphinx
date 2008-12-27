ActiveRecord::Base.connection.create_table :boxes, :force => true do |t|
  t.column :width,  :integer, :null => false
  t.column :length, :integer, :null => false
  t.column :depth,  :integer, :null => false
end

(1..10).each do |i|
  Box.create :width => i, :length => i, :depth => i
end
