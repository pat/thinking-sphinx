ActiveRecord::Base.connection.create_table :comments, :force => true do |t|
  t.column :name,     :string,  :null => false
  t.column :email,    :string
  t.column :url,      :string
  t.column :content,  :text
  t.column :post_id,  :integer, :null => false
end

Comment.create(
  :name     => "Pat",
  :content  => "+1",
  :post_id  => 1
)
