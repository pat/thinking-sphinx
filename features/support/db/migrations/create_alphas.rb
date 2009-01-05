ActiveRecord::Base.connection.create_table :alphas, :force => true do |t|
  t.column :name,       :string,  :null => false
  t.column :value,      :integer, :null => false
  t.column :cost,       :decimal, :precision => 10, :scale => 6
  t.column :created_on, :date
  t.column :created_at, :timestamp
end

Alpha.create :name => "one",    :value =>  1, :cost =>  1.51, :created_on =>  1.day.ago.to_date, :created_at =>  1.day.ago
Alpha.create :name => "two",    :value =>  2, :cost =>  2.52, :created_on =>  2.day.ago.to_date, :created_at =>  2.day.ago
Alpha.create :name => "three",  :value =>  3, :cost =>  3.53, :created_on =>  3.day.ago.to_date, :created_at =>  3.day.ago
Alpha.create :name => "four",   :value =>  4, :cost =>  4.54, :created_on =>  4.day.ago.to_date, :created_at =>  4.day.ago
Alpha.create :name => "five",   :value =>  5, :cost =>  5.55, :created_on =>  5.day.ago.to_date, :created_at =>  5.day.ago
Alpha.create :name => "six",    :value =>  6, :cost =>  6.56, :created_on =>  6.day.ago.to_date, :created_at =>  6.day.ago
Alpha.create :name => "seven",  :value =>  7, :cost =>  7.57, :created_on =>  7.day.ago.to_date, :created_at =>  7.day.ago
Alpha.create :name => "eight",  :value =>  8, :cost =>  8.58, :created_on =>  8.day.ago.to_date, :created_at =>  8.day.ago
Alpha.create :name => "nine",   :value =>  9, :cost =>  9.59, :created_on =>  9.day.ago.to_date, :created_at =>  9.day.ago
Alpha.create :name => "ten",    :value => 10, :cost => 10.50, :created_on => 10.day.ago.to_date, :created_at => 10.day.ago
