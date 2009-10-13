ActiveRecord::Base.connection.create_table :comments, :force => true do |t|
  t.column :name,     :string,  :null => false
  t.column :email,    :string
  t.column :url,      :string
  t.column :content,  :text
  t.column :post_id,  :integer, :null => false
  t.column :category_id, :integer, :null => false
  t.column :created_at, :datetime
  t.column :updated_at, :datetime
end
