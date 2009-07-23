class Person < ActiveRecord::Base
  define_index do
    indexes first_name, last_name, :sortable => true
    
    has [first_name, middle_initial, last_name], :as => :name_sort
    has birthday
    has gender, :facet => true
  end
  
  sphinx_scope(:with_first_name) { |name|
    { :conditions => {:first_name => name} }
  }
  sphinx_scope(:with_last_name) { |name|
    { :conditions => {:last_name => name} }
  }
  sphinx_scope(:with_id) { |id|
    { :with => {:sphinx_internal_id => id} }
  }
  sphinx_scope(:ids_only) { {:ids_only => true} }
end
