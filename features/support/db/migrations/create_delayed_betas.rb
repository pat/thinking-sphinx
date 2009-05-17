ActiveRecord::Base.connection.create_table :delayed_betas, :force => true do |t|
  t.column  :name, :string,  :null => false
  t.column :delta, :boolean, :null => false, :default => false
end

ActiveRecord::Base.connection.create_table :delayed_jobs, :force => true do |t|
  t.column :priority, :integer, :default => 0
  t.column :attempts, :integer, :default => 0
  t.column :handler, :text
  t.column :last_error, :string
  t.column :run_at, :datetime
  t.column :locked_at, :datetime
  t.column :failed_at, :datetime
  t.column :locked_by, :string
  t.column :created_at, :datetime
  t.column :updated_at, :datetime
end
