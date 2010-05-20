ActiveRecord::Base.connection.create_table :gammas, :force => true do |t|
  t.column :name, :string, :null => false
end
