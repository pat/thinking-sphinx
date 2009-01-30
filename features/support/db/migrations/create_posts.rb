ActiveRecord::Base.connection.create_table :posts, :force => true do |t|
  t.column :subject, :string,  :null => false
  t.column :content, :text
  t.column :category_id, :integer, :null => false
end

Post.create :subject => "Hello World", :content => "Um Text", :id => 1, :category_id => 1
