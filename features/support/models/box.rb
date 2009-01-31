class Box < ActiveRecord::Base
  define_index do
    indexes width, :as => :width_field
    
    has width, length, depth
    has [width, length, depth], :as => :dimensions
  end
end
