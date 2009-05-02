class Beta < ActiveRecord::Base
  define_index do
    indexes :name, :sortable => true
    has value
    
    set_property :delta => true
  end
end
