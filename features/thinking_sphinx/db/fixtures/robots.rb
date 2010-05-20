# Reset the primary key to allow us to create robots with specific internal_ids
class Robot < ActiveRecord::Base
  set_primary_key :alternate_primary_key
end

Robot.create :name => 'Fritz',      :internal_id => 'F0001'
Robot.create :name => 'Sizzle',     :internal_id => 'S0001'
Robot.create :name => 'Sizzle Jr.', :internal_id => 'S0002'
Robot.create :name => 'Expendable', :internal_id => 'E0001'

# Annnnnnnnnnd we're back
class Robot < ActiveRecord::Base
  set_primary_key :internal_id
end
