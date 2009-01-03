class Theta < ActiveRecord::Base
  define_index do
    indexes :name, :sortable => true
    
    set_property :delta => :datetime, :threshold => 1.hour
  end
end
