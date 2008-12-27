ActiveRecord::Base.connection.create_table :boxes, :force => true do |t|
  t.integer :width,   :null => false
  t.integer :length,  :null => false
  t.integer :depth,   :null => false
end

(1..10).each do |i|
  Box.create :width => i, :length => i, :depth => i
end
