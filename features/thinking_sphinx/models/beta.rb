class Beta < ActiveRecord::Base
  define_index do
    indexes :name, :sortable => true, :facet => true
    has value
  end
  
  define_index 'secondary_beta' do
    indexes :name, :sortable => true, :facet => true
    has value
    
    set_property :delta => true
  end
end
