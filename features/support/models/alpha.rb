class Alpha < ActiveRecord::Base
  define_index do
    indexes :name, :sortable => true
    
    has value, cost, created_at, created_on
    
    set_property :field_weights => {"name" => 10}
  end
end
