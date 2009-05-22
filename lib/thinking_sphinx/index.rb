require 'thinking_sphinx/index/builder'
require 'thinking_sphinx/index/faux_column'

module ThinkingSphinx
  # The Index class is a ruby representation of a Sphinx source (not a Sphinx
  # index - yes, I know it's a little confusing. You'll manage). This is
  # another 'internal' Thinking Sphinx class - if you're using it directly,
  # you either know what you're doing, or messing with things beyond your ken.
  # Enjoy.
  # 
  class Index
    attr_accessor :model, :sources, :delta_object
    
    # Create a new index instance by passing in the model it is tied to, and
    # a block to build it with (optional but recommended). For documentation
    # on the syntax for inside the block, the Builder class is what you want.
    #
    # Quick Example:
    #
    #   Index.new(User) do
    #     indexes login, email
    #     
    #     has created_at
    #     
    #     set_property :delta => true
    #   end
    #
    def initialize(model, &block)
      @model        = model
      @sources      = []
      @options      = {}
      @delta_object = nil
    end
    
    def fields
      @sources.collect { |source| source.fields }.flatten
    end
    
    def attributes
      @sources.collect { |source| source.attributes }.flatten
    end
    
    def name
      self.class.name(@model)
    end
    
    def self.name(model)
      model.name.underscore.tr(':/\\', '_')
    end
    
    def prefix_fields
      fields.select { |field| field.prefixes }
    end
    
    def infix_fields
      fields.select { |field| field.infixes }
    end
    
    def local_options
      @options
    end
    
    def options
      all_index_options = ThinkingSphinx::Configuration.instance.index_options.clone
      @options.keys.select { |key|
        ThinkingSphinx::Configuration::IndexOptions.include?(key.to_s)
      }.each { |key| all_index_options[key.to_sym] = @options[key] }
      all_index_options
    end
    
    def delta?
      !@delta_object.nil?
    end
    
    private
    
    def adapter
      @adapter ||= @model.sphinx_database_adapter
    end
    
    def utf8?
      options[:charset_type] == "utf-8"
    end
    
    # Does all the magic with the block provided to the base #initialize.
    # Creates a new class subclassed from Builder, and evaluates the block
    # on it, then pulls all relevant settings - fields, attributes, conditions,
    # properties - into the new index.
    # 
    def initialize_from_builder(&block)
      #
    end
    
    def sql_query_pre_for_delta
      [""]
    end
  end
end
