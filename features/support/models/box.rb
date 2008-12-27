class Box < ActiveRecord::Base
  define_index do
    indexes width, :as => :width_field
    
    has width, length, depth
  end
end