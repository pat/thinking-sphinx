ActiveRecord::Base.connection.create_table :betas, :force => true do |t|
  t.column :name, :string,  :null => false
  t.column :value, :integer, :null => false
  t.column :delta, :boolean, :null => false, :default => false
end

Beta.create :name => "one", :value => 1
Beta.create :name => "two", :value => 2
Beta.create :name => "three", :value => 3
Beta.create :name => "four", :value => 4
Beta.create :name => "five", :value => 5
Beta.create :name => "six", :value => 6
Beta.create :name => "seven", :value => 7
Beta.create :name => "eight", :value => 8
Beta.create :name => "nine", :value => 9
Beta.create :name => "ten", :value => 10
