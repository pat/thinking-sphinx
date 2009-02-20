require File.join(File.dirname(__FILE__), "..", "lib", "generic_delta_handler")

class ExtensibleBeta < ActiveRecord::Base
  define_index do
    indexes :name, :sortable => true
    
    set_property :delta => GenericDeltaHandler
  end
end
