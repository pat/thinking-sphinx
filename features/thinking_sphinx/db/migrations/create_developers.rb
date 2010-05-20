ActiveRecord::Base.connection.create_table :developers, :force => true do |t|
  t.column :name,     :string,  :null => false
  t.column :city,     :string
  t.column :state,    :string
  t.column :country,  :string
  t.column :age,      :integer
end
