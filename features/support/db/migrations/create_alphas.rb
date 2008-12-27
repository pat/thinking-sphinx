ActiveRecord::Base.connection.create_table :alphas, :force => true do |t|
  t.string  :name,  :null => false
  t.integer :value, :null => false
end

Alpha.create :name => "one",    :value =>  1
Alpha.create :name => "two",    :value =>  2
Alpha.create :name => "three",  :value =>  3
Alpha.create :name => "four",   :value =>  4
Alpha.create :name => "five",   :value =>  5
Alpha.create :name => "six",    :value =>  6
Alpha.create :name => "seven",  :value =>  7
Alpha.create :name => "eight",  :value =>  8
Alpha.create :name => "nine",   :value =>  9
Alpha.create :name => "ten",    :value => 10
