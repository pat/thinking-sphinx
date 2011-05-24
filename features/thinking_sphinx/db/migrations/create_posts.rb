ActiveRecord::Base.connection.create_table :posts, :force => true do |t|
  t.column :subject, :string,  :null => false
  t.column :content, :text
  t.column :category_id, :integer, :null => false
  t.column :keywords_file, :string
end
