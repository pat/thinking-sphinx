require "#{File.dirname(__FILE__)}/person"

class Andrew < ActiveRecord::Base
  set_table_name 'people'
  
  define_index do
    indexes first_name, last_name, street_address
  end
  
  sphinx_scope(:locked_first_name) {
    {:conditions => {:first_name => 'Andrew'}}
  }
  sphinx_scope(:locked_last_name) {
    {:conditions => {:last_name => 'Byrne'}}
  }
  default_sphinx_scope :locked_first_name
end
