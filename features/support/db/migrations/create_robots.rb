ActiveRecord::Base.connection.create_table :robots, :id => false, :force => true do |t|
  t.column :alternate_primary_key,  "int(11) DEFAULT NULL auto_increment PRIMARY KEY"
  t.column :name,                   :string,  :null => false
  t.column :internal_id,            :string,  :null => false
end

# reset the primary key to allow us to create robots with specific internal_ids
class Robot < ActiveRecord::Base
  set_primary_key :id
end

Robot.create(:name => 'Fritz', :internal_id => 'F0001')
Robot.create(:name => 'Sizzle', :internal_id => 'S0001')
Robot.create(:name => 'Sizzle Jr.', :internal_id => 'S0002')

# annnnnnnnnnd we're back
class Robot < ActiveRecord::Base
  set_primary_key :internal_id
end