require 'faker'

ActiveRecord::Base.connection.create_table :developers, :force => true do |t|
  t.column :name,     :string,  :null => false
  t.column :city,     :string
  t.column :state,    :string
  t.column :country,  :string
  t.column :age,      :integer
end

Developer.create :name => "Pat Allan", :city => "Melbourne", :state => "Victoria", :country => "Australia", :age => 26

2.times do
  Developer.create :name => Faker::Name.name, :city => "Melbourne", :state => "Victoria", :country => "Australia", :age => 30
end

2.times do
  Developer.create :name => Faker::Name.name, :city => "Sydney", :state => "New South Wales", :country => "Australia", :age => 28
end

2.times do
  Developer.create :name => Faker::Name.name, :city => "Adelaide", :state => "South Australia", :country => "Australia", :age => 32
end

2.times do
  Developer.create :name => Faker::Name.name, :city => "Bendigo", :state => "Victoria", :country => "Australia", :age => 30
end

2.times do
  Developer.create :name => Faker::Name.name, :city => "Goulburn", :state => "New South Wales", :country => "Australia", :age => 28
end

2.times do
  Developer.create :name => Faker::Name.name, :city => "Auckland", :state => "North Island", :country => "New Zealand", :age => 32
end

2.times do
  Developer.create :name => Faker::Name.name, :city => "Christchurch", :state => "South Island", :country => "New Zealand", :age => 30
end
