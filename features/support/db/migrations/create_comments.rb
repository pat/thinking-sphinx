ActiveRecord::Base.connection.create_table :comments, :force => true do |t|
  t.string  :name,    :null => false
  t.string  :email
  t.string  :url
  t.text    :content
  t.integer :post_id, :null => false
end

Comment.create(
  :name     => "Pat",
  :content  => "+1",
  :post_id  => 1
)
