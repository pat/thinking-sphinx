require 'after_commit'

require 'thinking_sphinx/active_record/attribute_updates'
require 'thinking_sphinx/active_record/has_many_association'

# Core additions to ActiveRecord models - define_index for creating indexes
# for models. If you want to interrogate the index objects created for the
# model, you can use the class-level accessor :sphinx_indexes.
#
module ThinkingSphinx::ActiveRecord
  def self.included(base)
    base.class_eval do
      extend ThinkingSphinx::ActiveRecord::ClassMethods
    end
  end
  
  module ClassMethods
    def set_sphinx_primary_key(attribute)
      @sphinx_primary_key_attribute = attribute
    end
    
    def primary_key_for_sphinx
      @sphinx_primary_key_attribute || primary_key
    end
    
    private
          
    def add_initial_sphinx_callbacks
      super
      
      before_validation :process_indexes
      before_destroy    :process_indexes
    end
    
    def add_standard_sphinx_callbacks
      super
      
      after_destroy :toggle_deleted
      
      include ThinkingSphinx::ActiveRecord::AttributeUpdates
    end
    
    def add_delta_sphinx_callbacks
      super
      
      before_save   :toggle_delta
      after_commit  :index_delta
    end
    
    def absolute_superclass
      ::ActiveRecord::Base
    end
  end
  
  # Returns the unique integer id for the object. This method uses the
  # attribute hash to get around ActiveRecord always mapping the #id method
  # to whatever the real primary key is (which may be a unique string hash).
  # 
  # @return [Integer] Unique record id for the purposes of Sphinx.
  # 
  def primary_key_for_sphinx
    @primary_key_for_sphinx ||= read_attribute(self.class.primary_key_for_sphinx)
  end

  private
  
  def process_indexes
    self.class.process_indexes
  end
end

ActiveRecord::Base.class_eval do
  include ThinkingSphinx::Base
  include ThinkingSphinx::ActiveRecord
end

ActiveRecord::Associations::HasManyAssociation.class_eval do
  include ThinkingSphinx::ActiveRecord::HasManyAssociation
end

ActiveRecord::Associations::HasManyThroughAssociation.class_eval do
  include ThinkingSphinx::ActiveRecord::HasManyAssociation
end
