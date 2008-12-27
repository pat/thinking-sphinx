ActiveRecord::Base.connection.create_table :posts, :force => true do |t|
  t.string  :subject,  :null => false
  t.text    :content
end

Post.create :subject => "Hello World", :content => "Um Text"
