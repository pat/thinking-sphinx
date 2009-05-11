require 'thinking_sphinx/active_record/attribute_updates'
require 'thinking_sphinx/active_record/delta'
require 'thinking_sphinx/active_record/search'
require 'thinking_sphinx/active_record/has_many_association'

module ThinkingSphinx
  # Core additions to ActiveRecord models - define_index for creating indexes
  # for models. If you want to interrogate the index objects created for the
  # model, you can use the class-level accessor :sphinx_indexes.
  #
  module ActiveRecord
    def self.included(base)
      base.class_eval do
        class_inheritable_array :sphinx_indexes, :sphinx_facets
        class << self
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
          def define_index(&block)
            return unless ThinkingSphinx.define_indexes?
            
            self.sphinx_indexes ||= []
            index = ThinkingSphinx::Index::Builder.generate(self, &block)
            
            self.sphinx_indexes << index
            unless ThinkingSphinx.indexed_models.include?(self.name)
              ThinkingSphinx.indexed_models << self.name
            end
            
            if index.delta?
              before_save   :toggle_delta
              after_commit  :index_delta
            end
            
            after_destroy :toggle_deleted
            
            include ThinkingSphinx::ActiveRecord::AttributeUpdates
            
            index
          end
          alias_method :sphinx_index, :define_index
          
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
          
          def source_of_sphinx_index
            possible_models = self.sphinx_indexes.collect { |index| index.model }
            return self if possible_models.include?(self)

            parent = self.superclass
            while !possible_models.include?(parent) && parent != ::ActiveRecord::Base
              parent = parent.superclass
            end

            return parent
          end
          
          def to_riddle(offset)
            sphinx_database_adapter.setup
            
            indexes = [to_riddle_for_core(offset)]
            indexes << to_riddle_for_delta(offset) if sphinx_delta?
            indexes << to_riddle_for_distributed
          end
          
          def sphinx_database_adapter
            @sphinx_database_adapter ||=
              ThinkingSphinx::AbstractAdapter.detect(self)
          end
          
          private
          
          def sphinx_name
            self.name.underscore.tr(':/\\', '_')
          end
          
          def sphinx_delta?
            self.sphinx_indexes.any? { |index| index.delta? }
          end
          
          def to_riddle_for_core(offset)
            index = Riddle::Configuration::Index.new("#{sphinx_name}_core")
            index.path = File.join(
              ThinkingSphinx::Configuration.instance.searchd_file_path, index.name
            )
            
            set_configuration_options_for_indexes index
            set_field_settings_for_indexes        index
            
            self.sphinx_indexes.select { |ts_index|
              ts_index.model == self
            }.each_with_index do |ts_index, i|
              index.sources += ts_index.sources.collect { |source|
                source.to_riddle_for_core(offset, i)
              }
            end
            
            index
          end
          
          def to_riddle_for_delta(offset)
            index = Riddle::Configuration::Index.new("#{sphinx_name}_delta")
            index.parent = "#{sphinx_name}_core"
            index.path = File.join(ThinkingSphinx::Configuration.instance.searchd_file_path, index.name)
            
            self.sphinx_indexes.each_with_index do |ts_index, i|
              index.sources += ts_index.sources.collect { |source|
                source.to_riddle_for_delta(offset, i)
              } if ts_index.delta?
            end
            
            index
          end
          
          def to_riddle_for_distributed
            index = Riddle::Configuration::DistributedIndex.new(sphinx_name)
            index.local_indexes << "#{sphinx_name}_core"
            index.local_indexes.unshift "#{sphinx_name}_delta" if sphinx_delta?
            index
          end
          
          def set_configuration_options_for_indexes(index)
            ThinkingSphinx::Configuration.instance.index_options.each do |key, value|
              index.send("#{key}=".to_sym, value)
            end
            
            self.sphinx_indexes.each do |ts_index|
              ts_index.options.each do |key, value|
                index.send("#{key}=".to_sym, value) if ThinkingSphinx::Configuration::IndexOptions.include?(key.to_s) && !value.nil?
              end
            end
          end
          
          def set_field_settings_for_indexes(index)
            field_names = lambda { |field| field.unique_name.to_s }
            
            self.sphinx_indexes.each do |ts_index|
              index.prefix_field_names += ts_index.prefix_fields.collect(&field_names)
              index.infix_field_names  += ts_index.infix_fields.collect(&field_names)
            end
          end
        end
      end
      
      base.send(:include, ThinkingSphinx::ActiveRecord::Delta)
      base.send(:include, ThinkingSphinx::ActiveRecord::Search)
      
      ::ActiveRecord::Associations::HasManyAssociation.send(
        :include, ThinkingSphinx::ActiveRecord::HasManyAssociation
      )
      ::ActiveRecord::Associations::HasManyThroughAssociation.send(
        :include, ThinkingSphinx::ActiveRecord::HasManyAssociation
      )
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
      return unless ThinkingSphinx.updates_enabled? && ThinkingSphinx.sphinx_running?
      
      config = ThinkingSphinx::Configuration.instance
      client = Riddle::Client.new config.address, config.port
      
      client.update(
        "#{self.class.sphinx_indexes.first.name}_core",
        ['sphinx_deleted'],
        {self.sphinx_document_id => 1}
      ) if self.in_core_index?
      
      client.update(
        "#{self.class.sphinx_indexes.first.name}_delta",
        ['sphinx_deleted'],
        {self.sphinx_document_id => 1}
      ) if ThinkingSphinx.deltas_enabled? &&
        self.class.sphinx_indexes.any? { |index| index.delta? } &&
        self.toggled_delta?
    rescue ::ThinkingSphinx::ConnectionError
      # nothing
    end
    
    def sphinx_document_id
      (self.id * ThinkingSphinx.indexed_models.size) +
        ThinkingSphinx.indexed_models.index(self.class.source_of_sphinx_index.name)
    end
    
    private
    
    def sphinx_index_name(suffix)
      "#{self.class.source_of_sphinx_index.name.underscore.tr(':/\\', '_')}_#{suffix}"
    end
  end
end
