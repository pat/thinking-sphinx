require 'after_commit'

require 'thinking_sphinx/active_record/attribute_updates'
require 'thinking_sphinx/active_record/delta'
require 'thinking_sphinx/active_record/has_many_association'
require 'thinking_sphinx/active_record/scopes'

module ThinkingSphinx
  # Core additions to ActiveRecord models - define_index for creating indexes
  # for models. If you want to interrogate the index objects created for the
  # model, you can use the class-level accessor :sphinx_indexes.
  #
  module ActiveRecord
    def self.included(base)
      base.class_eval do
        extend ThinkingSphinx::ActiveRecord::ClassMethods
        
        class << self
          def set_sphinx_primary_key(attribute)
            @sphinx_primary_key_attribute = attribute
          end
          
          def primary_key_for_sphinx
            @sphinx_primary_key_attribute || primary_key
          end
          
          def sphinx_database_adapter
            @sphinx_database_adapter ||=
              ThinkingSphinx::AbstractAdapter.detect(self)
          end
          
          def sphinx_name
            self.name.underscore.tr(':/\\', '_')
          end
          
          private
          
          def sphinx_delta?
            self.sphinx_indexes.any? { |index| index.delta? }
          end
        end
      end
      
      ::ActiveRecord::Associations::HasManyAssociation.send(
        :include, ThinkingSphinx::ActiveRecord::HasManyAssociation
      )
      ::ActiveRecord::Associations::HasManyThroughAssociation.send(
        :include, ThinkingSphinx::ActiveRecord::HasManyAssociation
      )
    end
    
    module ClassMethods
      def source_of_sphinx_index
        process_indexes
        possible_models = self.sphinx_indexes.collect { |index| index.model }
        return self if possible_models.include?(self)

        parent = self.superclass
        while !possible_models.include?(parent) && parent != ::ActiveRecord::Base
          parent = parent.superclass
        end

        return parent
      end
      
      private
            
      def add_initial_sphinx_callbacks
        before_validation :process_indexes
        before_destroy    :process_indexes
        
        include ThinkingSphinx::ActiveRecord::Scopes
        include ThinkingSphinx::SearchMethods
      end
      
      def add_standard_sphinx_callbacks
        after_destroy :toggle_deleted
        
        include ThinkingSphinx::ActiveRecord::AttributeUpdates
      end
      
      def add_delta_sphinx_callbacks
        include ThinkingSphinx::ActiveRecord::Delta
          
        before_save   :toggle_delta
        after_commit  :index_delta
      end
    end
    
    def in_index?(suffix)
      self.class.search_for_id self.sphinx_document_id, sphinx_index_name(suffix)
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

    def sphinx_index_name(suffix)
      "#{self.class.source_of_sphinx_index.name.underscore.tr(':/\\', '_')}_#{suffix}"
    end
    
    def process_indexes
      self.class.process_indexes
    end
  end
end

ActiveRecord::Base.class_eval do
  include ThinkingSphinx::Base
  include ThinkingSphinx::ActiveRecord
end
