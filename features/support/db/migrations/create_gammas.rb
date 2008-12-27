ActiveRecord::Base.connection.create_table :gammas, :force => true do |t|
  t.column :name, :string, :null => false
end

Gamma.create :name => "one"
Gamma.create :name => "two"
Gamma.create :name => "three"
Gamma.create :name => "four"
Gamma.create :name => "five"
Gamma.create :name => "six"
Gamma.create :name => "seven"
Gamma.create :name => "eight"
Gamma.create :name => "nine"
Gamma.create :name => "ten"
