ActiveRecord::Base.connection.create_table(
  :authors_posts, :force => true, :id => false
) do |t|
  t.column :author_id, :integer, :null => false
  t.column :post_id,   :integer, :null => false
end
