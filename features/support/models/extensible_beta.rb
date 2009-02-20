class ExtensibleBeta < ActiveRecord::Base
  define_index do
    indexes :name, :sortable => true
    
    set_property :delta => true
  end
end
