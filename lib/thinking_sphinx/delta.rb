module ThinkingSphinx::Delta
  def self.included(base)
    base.class_eval do
      extend ThinkingSphinx::Delta::ClassMethods
    end
  end
  
  module ClassMethods
    # Build the delta index for the related model. This won't be called
    # if running in the test environment.
    #
    def index_delta(instance = nil)
      delta_object.index(self, instance)
    end
    
    def delta_object
      sphinx_indexes.first.delta_object
    end
  end
  
  private
  
  # Set the delta value for the model to be true.
  def toggle_delta
    self.class.delta_object.toggle(self) if should_toggle_delta?
  end
  
  # Build the delta index for the related model. This won't be called
  # if running in the test environment.
  # 
  def index_delta
    self.class.index_delta(self) if self.class.delta_object.toggled(self)
  end
  
  def should_toggle_delta?
    new_record_for_sphinx? || indexed_data_changed?
  end
  
  def indexed_data_changed?
    self.class.sphinx_indexes.any? { |index|
      index.fields.any? { |field| field.changed?(self) } ||
      index.attributes.any? { |attrib|
        attrib.public? && attrib.changed?(self) && !attrib.updatable?
      }
    }
  end
end
