module ThinkingSphinx::DataMapper
  def self.included(base)
    base.class_eval do
      extend ThinkingSphinx::DataMapper::ClassMethods
    end
  end
  
  module ClassMethods
    private
          
    def add_initial_sphinx_callbacks
      super
      
      # before_validation :process_indexes
      # before_destroy    :process_indexes
    end
    
    def add_standard_sphinx_callbacks
      super
      
      # after_destroy :toggle_deleted
      
      # include ThinkingSphinx::ActiveRecord::AttributeUpdates
    end
    
    def add_delta_sphinx_callbacks
      super
      
      # before_save   :toggle_delta
      # after_commit  :index_delta
    end
  end
  
  def primary_key_for_sphinx
    id
  end
end

DataMapper::Resource.class_eval do
  include ThinkingSphinx::Base
  include ThinkingSphinx::DataMapper
end
