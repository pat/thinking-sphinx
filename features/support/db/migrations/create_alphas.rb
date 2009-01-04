ActiveRecord::Base.connection.create_table :alphas, :force => true do |t|
  t.column :name,  :string,  :null => false
  t.column :value, :integer, :null => false
  t.column :cost,  :decimal, :precision => 10, :scale => 6
end

Alpha.create :name => "one",    :value =>  1, :cost =>  1.51
Alpha.create :name => "two",    :value =>  2, :cost =>  2.52
Alpha.create :name => "three",  :value =>  3, :cost =>  3.53
Alpha.create :name => "four",   :value =>  4, :cost =>  4.54
Alpha.create :name => "five",   :value =>  5, :cost =>  5.55
Alpha.create :name => "six",    :value =>  6, :cost =>  6.56
Alpha.create :name => "seven",  :value =>  7, :cost =>  7.57
Alpha.create :name => "eight",  :value =>  8, :cost =>  8.58
Alpha.create :name => "nine",   :value =>  9, :cost =>  9.59
Alpha.create :name => "ten",    :value => 10, :cost => 10.50
