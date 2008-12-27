ActiveRecord::Base.connection.create_table :betas, :force => true do |t|
  t.string  :name,  :null => false
  t.boolean :delta, :null => false, :default => false
end

Beta.create :name => "one"
Beta.create :name => "two"
Beta.create :name => "three"
Beta.create :name => "four"
Beta.create :name => "five"
Beta.create :name => "six"
Beta.create :name => "seven"
Beta.create :name => "eight"
Beta.create :name => "nine"
Beta.create :name => "ten"
