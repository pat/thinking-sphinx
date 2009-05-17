ActiveRecord::Base.connection.create_table :tags, :force => true do |t|
  # t.column :post_id, :integer, :null => false
  t.column :text,       :text,  :null => true
end
