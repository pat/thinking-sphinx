ActiveRecord::Base.connection.create_table :robots, :primary_key => :alternate_primary_key, :force => true do |t|
  t.column :name,                   :string,  :null => false
  t.column :internal_id,            :string,  :null => false
end
