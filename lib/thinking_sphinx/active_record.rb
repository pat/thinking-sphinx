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
        class_inheritable_array :sphinx_indexes, :sphinx_facets
        
        extend ThinkingSphinx::ActiveRecord::ClassMethods
        
        class << self
          def set_sphinx_primary_key(attribute)
            @sphinx_primary_key_attribute = attribute
          end
          
          def primary_key_for_sphinx
            @sphinx_primary_key_attribute || primary_key
          end
          
          def sphinx_index_options
            sphinx_indexes.last.options
          end
          
          # Generate a unique CRC value for the model's name, to use to
          # determine which Sphinx documents belong to which AR records.
          # 
          # Really only written for internal use - but hey, if it's useful to
          # you in some other way, awesome.
          # 
          def to_crc32
            self.name.to_crc32
          end
          
          def to_crc32s
            (subclasses << self).collect { |klass| klass.to_crc32 }
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
      # Allows creation of indexes for Sphinx. If you don't do this, there
      # isn't much point trying to search (or using this plugin at all,
      # really).
      #
      # An example or two:
      #
      #   define_index
      #     indexes :id, :as => :model_id
      #     indexes name
      #   end
      #
      # You can also grab fields from associations - multiple levels deep
      # if necessary.
      #
      #   define_index do
      #     indexes tags.name, :as => :tag
      #     indexes articles.content
      #     indexes orders.line_items.product.name, :as => :product
      #   end
      #
      # And it will automatically concatenate multiple fields:
      #
      #   define_index do
      #     indexes [author.first_name, author.last_name], :as => :author
      #   end
      #
      # The #indexes method is for fields - if you want attributes, use
      # #has instead. All the same rules apply - but keep in mind that
      # attributes are for sorting, grouping and filtering, not searching.
      #
      #   define_index do
      #     # fields ...
      #     
      #     has created_at, updated_at
      #   end
      #
      # One last feature is the delta index. This requires the model to
      # have a boolean field named 'delta', and is enabled as follows:
      #
      #   define_index do
      #     # fields ...
      #     # attributes ...
      #     
      #     set_property :delta => true
      #   end
      #
      # Check out the more detailed documentation for each of these methods
      # at ThinkingSphinx::Index::Builder.
      # 
      def define_index(name = nil, &block)
        return unless ThinkingSphinx.define_indexes?
        
        self.sphinx_indexes ||= []
        self.sphinx_facets  ||= []
        
        index = ThinkingSphinx::Index::Builder.generate self, name, &block
        
        unless ThinkingSphinx.indexed_models.include?(self.name)
          ThinkingSphinx.indexed_models << self.name
          ThinkingSphinx.indexed_models.sort!
        end
        
        add_sphinx_callbacks_and_extend(index.delta?)
        self.sphinx_indexes << index
        
        index
        
        # We want to make sure that if the database doesn't exist, then Thinking
        # Sphinx doesn't mind when running non-TS tasks (like db:create, db:drop
        # and db:migrate). It's a bit hacky, but I can't think of a better way.
      rescue StandardError => err
        case err.class.name
        when "Mysql::Error", "Java::JavaSql::SQLException", "ActiveRecord::StatementInvalid"
          return
        else
          raise err
        end
      end
      
      def indexed_by_sphinx?
        sphinx_indexes && sphinx_indexes.length > 0
      end
      
      def delta_indexed_by_sphinx?
        sphinx_indexes && sphinx_indexes.any? { |index| index.delta? }
      end
      
      def sphinx_index_names
        sphinx_indexes.collect(&:all_names).flatten
      end
      
      def core_index_names
        sphinx_indexes.collect(&:core_name)
      end
      
      def delta_index_names
        sphinx_indexes.select(&:delta?).collect(&:delta_name)
      end
      
      def to_riddle
        sphinx_database_adapter.setup
        
        local_sphinx_indexes.collect { |index|
          index.to_riddle(sphinx_offset)
        }.flatten
      end
      
      def source_of_sphinx_index
        possible_models = self.sphinx_indexes.collect { |index| index.model }
        return self if possible_models.include?(self)

        parent = self.superclass
        while !possible_models.include?(parent) && parent != ::ActiveRecord::Base
          parent = parent.superclass
        end

        return parent
      end
      
      def delete_in_index(index, document_id)
        return unless ThinkingSphinx.sphinx_running? &&
          search_for_id(document_id, index)
        
        ThinkingSphinx::Configuration.instance.client.update(
          index, ['sphinx_deleted'], {document_id => [1]}
        )
      end
      
      def sphinx_offset
        ThinkingSphinx.superclass_indexed_models.index eldest_indexed_ancestor
      end
      
      private
      
      def local_sphinx_indexes
        sphinx_indexes.select { |index|
          index.model == self
        }
      end
      
      def add_sphinx_callbacks_and_extend(delta = false)
        unless indexed_by_sphinx?
          after_destroy :toggle_deleted
      
          include ThinkingSphinx::SearchMethods
          include ThinkingSphinx::ActiveRecord::AttributeUpdates
          include ThinkingSphinx::ActiveRecord::Scopes
        end
        
        if delta && !delta_indexed_by_sphinx?
          include ThinkingSphinx::ActiveRecord::Delta
          
          before_save   :toggle_delta
          after_commit  :index_delta
        end
      end
      
      def eldest_indexed_ancestor
        ancestors.reverse.detect { |ancestor|
          ThinkingSphinx.indexed_models.include?(ancestor.name)
        }.name
      end
    end
    
    def in_index?(suffix)
      self.class.search_for_id self.sphinx_document_id, sphinx_index_name(suffix)
    end
    
    def in_core_index?
      in_index? "core"
    end
    
    def in_delta_index?
      in_index? "delta"
    end
    
    def in_both_indexes?
      in_core_index? && in_delta_index?
    end
    
    def toggle_deleted
      return unless ThinkingSphinx.updates_enabled?
      
      self.class.core_index_names.each do |index_name|
        self.class.delete_in_index index_name, self.sphinx_document_id
      end
      self.class.delta_index_names.each do |index_name|
        self.class.delete_in_index index_name, self.sphinx_document_id
      end if self.class.delta_indexed_by_sphinx? && toggled_delta?
      
    rescue ::ThinkingSphinx::ConnectionError
      # nothing
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
    
    def sphinx_document_id
      primary_key_for_sphinx * ThinkingSphinx.indexed_models.size +
        self.class.sphinx_offset
    end

    private

    def sphinx_index_name(suffix)
      "#{self.class.source_of_sphinx_index.name.underscore.tr(':/\\', '_')}_#{suffix}"
    end
  end
end
