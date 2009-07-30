ActiveRecord::Base.connection.create_table :robots, :id => false, :force => true do |t|
  t.column :alternate_primary_key,  "int(11) DEFAULT NULL auto_increment PRIMARY KEY"
  t.column :name,                   :string,  :null => false
  t.column :internal_id,            :string,  :null => false
end
