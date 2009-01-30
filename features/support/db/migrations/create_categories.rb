ActiveRecord::Base.connection.create_table :categories, :force => true do |t|
  t.column :name, :string
end

Category.create :name => "hello"
