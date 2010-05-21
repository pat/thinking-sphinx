ActiveRecord::Base.connection.create_table :people, :force => true do |t|
  t.column :first_name,     :string
  t.column :middle_initial, :string
  t.column :last_name,      :string
  t.column :gender,         :string
  t.column :street_address, :string
  t.column :city,           :string
  t.column :state,          :string
  t.column :postcode,       :string
  t.column :email,          :string
  t.column :birthday,       :datetime
  t.column :delta, :boolean, :null => false, :default => false
end
