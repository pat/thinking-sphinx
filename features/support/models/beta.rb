class Beta < ActiveRecord::Base
  set_table_name 'betas'
  
  define_index do
    indexes :name, :sortable => true
    has value
    
    set_property :delta => true
  end
end
