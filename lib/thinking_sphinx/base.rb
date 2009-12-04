module ThinkingSphinx::Base
  module ClassMethods
    def define_index(name = nil, &block)
      ThinkingSphinx.context.add_indexed_model self
      
      add_initial_sphinx_callbacks if sphinx_index_blocks.empty?
      
      sphinx_index_blocks << [self, name, block]
    end
    
    def process_indexes
      return unless ThinkingSphinx.define_indexes?
      
      sphinx_index_blocks.each do |klass, name, block|
        process_index(name, &block) if self == klass
      end
      
      sphinx_index_blocks.clear
    end
    
    def process_index(name, &block)
      index = ThinkingSphinx::Index::Builder.generate self, name, &block
      
      add_standard_sphinx_callbacks unless indexed_by_sphinx?
      add_delta_sphinx_callbacks    if index.delta? && !delta_indexed_by_sphinx?
      
      add_sphinx_index index
    end
    
    def add_sphinx_index(index)
      sphinx_indexes << index
      
      subclasses.each do |subclass|
        subclass = subclass.constantize if subclass.is_a?(String)
        subclass.add_sphinx_index index
      end
    end
    
    def to_crc32
      self.name.to_crc32
    end
    
    def to_crc32s
      subclasses.inject([self.name.to_crc32]) do |array, subclass|
        array << subclass.to_crc32
      end
    end
    
    def sphinx_offset
      ThinkingSphinx.context.superclass_indexed_models.
        index eldest_indexed_ancestor
    end
    
    def has_sphinx_indexes?
      sphinx_indexes      && 
      sphinx_index_blocks &&
      (sphinx_indexes.length > 0 || sphinx_index_blocks.length > 0)
    end
    
    def indexed_by_sphinx?
      sphinx_indexes && sphinx_indexes.length > 0
    end
    
    def delta_indexed_by_sphinx?
      sphinx_indexes && sphinx_indexes.any? { |index| index.delta? }
    end
    
    def sphinx_index_names
      process_indexes
      sphinx_indexes.collect(&:all_names).flatten
    end
    
    def core_index_names
      process_indexes
      sphinx_indexes.collect(&:core_name)
    end
    
    def delta_index_names
      process_indexes
      sphinx_indexes.select(&:delta?).collect(&:delta_name)
    end
    
    def to_riddle
      process_indexes
      sphinx_database_adapter.setup
      
      local_sphinx_indexes.collect { |index|
        index.to_riddle(sphinx_offset)
      }.flatten
    end
    
    def sphinx_index_options
      sphinx_indexes.last.options
    end
    
    # Temporarily disable delta indexing inside a block, then perform a single
    # rebuild of index at the end.
    #
    # Useful when performing updates to batches of models to prevent
    # the delta index being rebuilt after each individual update.
    #
    # In the following example, the delta index will only be rebuilt once,
    # not 10 times.
    #
    #   SomeModel.suspended_delta do
    #     10.times do
    #       SomeModel.create( ... )
    #     end
    #   end
    # 
    def suspended_delta(reindex_after = true, &block)
      process_indexes
      original_setting = ThinkingSphinx.deltas_enabled?
      ThinkingSphinx.deltas_enabled = false
      begin
        yield
      ensure
        ThinkingSphinx.deltas_enabled = original_setting
        self.index_delta if reindex_after
      end
    end
    
    def source_of_sphinx_index
      process_indexes
      possible_models = self.sphinx_indexes.collect { |index| index.model }
      return self if possible_models.include?(self)

      parent = self.superclass
      while !possible_models.include?(parent) && parent != absolute_superclass
        parent = parent.superclass
      end

      return parent
    end
    
    def sphinx_database_adapter
      @sphinx_database_adapter ||=
        ThinkingSphinx::AbstractAdapter.detect(self)
    end
    
    private
    
    def add_initial_sphinx_callbacks
      include ThinkingSphinx::Scopes
      include ThinkingSphinx::SearchMethods
    end
    
    def add_standard_sphinx_callbacks
      #
    end
    
    def add_delta_sphinx_callbacks
      include ThinkingSphinx::Delta
    end
    
    def absolute_superclass
      Object
    end
    
    def indexed_by_sphinx?
      sphinx_indexes.length > 0
    end
    
    def delta_indexed_by_sphinx?
      sphinx_indexes.any? { |index| index.delta? }
    end
    
    def eldest_indexed_ancestor
      ancestors.reverse.detect { |ancestor|
        ThinkingSphinx.context.indexed_models.include?(ancestor.name)
      }.name
    end
    
    def local_sphinx_indexes
      sphinx_indexes.select { |index|
        index.model == self
      }
    end
  end
  
  def self.included(base)
    base.extend ThinkingSphinx::Base::ClassMethods
    
    base.class_eval do
      class_inheritable_array :sphinx_index_blocks, :sphinx_indexes,
        :sphinx_facets
      
      self.sphinx_index_blocks = []
      self.sphinx_indexes      = []
      self.sphinx_facets       = []
    end
  end
  
  def toggle_deleted
    self.class.sphinx_indexes.each do |index|
      index.toggle_deleted sphinx_document_id
    end
  end
  
  def sphinx_document_id
    primary_key_for_sphinx * ThinkingSphinx.context.indexed_models.size +
      self.class.sphinx_offset
  end
  
  def primary_key_for_sphinx
    -1
  end
end
