ActiveRecord::Base.connection.create_table :delayed_betas, :force => true do |t|
  t.column  :name, :string,  :null => false
  t.column :delta, :boolean, :null => false, :default => false
end

ActiveRecord::Base.connection.create_table :delayed_jobs, :force => true do |t|
  t.integer  :priority, :default => 0
  t.integer  :attempts, :default => 0
  t.text     :handler
  t.string   :last_error
  t.datetime :run_at
  t.datetime :locked_at
  t.datetime :failed_at
  t.string   :locked_by
  t.timestamps
end

DelayedBeta.create :name => "one"
DelayedBeta.create :name => "two"
DelayedBeta.create :name => "three"
DelayedBeta.create :name => "four"
DelayedBeta.create :name => "five"
DelayedBeta.create :name => "six"
DelayedBeta.create :name => "seven"
DelayedBeta.create :name => "eight"
DelayedBeta.create :name => "nine"
DelayedBeta.create :name => "ten"
