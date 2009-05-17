ActiveRecord::Base.connection.create_table :extensible_betas, :force => true do |t|
  t.column  :name, :string,  :null => false
  t.column :delta, :boolean, :null => false, :default => false
  t.column :changed_by_generic, :boolean, :null => false, :default => false
end
