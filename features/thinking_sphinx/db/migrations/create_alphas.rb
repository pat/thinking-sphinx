ActiveRecord::Base.connection.create_table :alphas, :force => true do |t|
  t.column :name,       :string,  :null => false
  t.column :value,      :integer, :null => false
  t.column :active,     :boolean, :null => false, :default => true
  t.column :cost,       :decimal, :precision => 10, :scale => 6
  t.column :created_on, :date
  t.column :created_at, :timestamp
end
