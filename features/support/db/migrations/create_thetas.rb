ActiveRecord::Base.connection.create_table :thetas, :force => true do |t|
  t.column :name,       :string,    :null => false
  t.column :created_at, :datetime,  :null => false
  t.column :updated_at, :datetime,  :null => false
end
