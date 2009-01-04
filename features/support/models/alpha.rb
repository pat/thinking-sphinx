class Alpha < ActiveRecord::Base
  define_index do
    indexes :name, :sortable => true
    
    has value, cost
    
    set_property :field_weights => {"name" => 10}
  end
end
