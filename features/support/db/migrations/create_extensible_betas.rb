ActiveRecord::Base.connection.create_table :extensible_betas, :force => true do |t|
  t.column  :name, :string,  :null => false
  t.column :delta, :boolean, :null => false, :default => false
  t.column :changed_by_generic, :boolean, :null => false, :default => false
end

ExtensibleBeta.create :name => "one"
ExtensibleBeta.create :name => "two"
ExtensibleBeta.create :name => "three"
ExtensibleBeta.create :name => "four"
ExtensibleBeta.create :name => "five"
ExtensibleBeta.create :name => "six"
ExtensibleBeta.create :name => "seven"
ExtensibleBeta.create :name => "eight"
ExtensibleBeta.create :name => "nine"
ExtensibleBeta.create :name => "ten"