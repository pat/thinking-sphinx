class Person < ActiveRecord::Base
  define_index do
    indexes first_name, last_name, :sortable => true
    
    has [first_name, middle_initial, last_name], :as => :name_sort
    has birthday
  end
end
