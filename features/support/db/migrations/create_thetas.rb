ActiveRecord::Base.connection.create_table :thetas, :force => true do |t|
  t.column :name,       :string,    :null => false
  t.column :created_at, :datetime,  :null => false
  t.column :updated_at, :datetime,  :null => false
end

Theta.create :name => "one"
Theta.create :name => "two"
Theta.create :name => "three"
Theta.create :name => "four"
Theta.create :name => "five"
Theta.create :name => "six"
Theta.create :name => "seven"
Theta.create :name => "eight"
Theta.create :name => "nine"
Theta.create :name => "ten"
