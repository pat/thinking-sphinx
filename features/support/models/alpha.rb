class Alpha < ActiveRecord::Base
  define_index do
    indexes :name, :sortable => true
    
    has value, created_at, created_on
    has cost, :facet => true
    
    set_property :field_weights => {"name" => 10}
  end
  
  define_index 'alternative' do
    indexes :name, :as => :alternative_name, :sortable => true
    
    has value, created_at, created_on
    has cost, :facet => true
    
    set_property :field_weights => {'alternative_name' => 10}
    
    where "value > 3"
  end
end
