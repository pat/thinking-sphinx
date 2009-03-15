ActiveRecord::Base.connection.create_table :taggings, :force => true do |t|
  t.column :tag_id,         :integer, :null => false
  t.column :taggable_id,    :integer, :null => false
  t.column :taggable_type,  :string,  :null => false
end
