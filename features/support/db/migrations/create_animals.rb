ActiveRecord::Base.connection.create_table :animals, :force => true do |t|
  t.string  :name,  :null => false
  t.string  :type
  t.boolean :delta, :null => false, :default => false
end

%w( rogue nat molly jasper moggy ).each do |name|
  Cat.create :name => name
end
