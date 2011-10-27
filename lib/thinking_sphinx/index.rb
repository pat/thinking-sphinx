require 'thinking_sphinx/index/builder'
require 'thinking_sphinx/index/faux_column'

module ThinkingSphinx
  class Index
    attr_accessor :name, :model, :sources, :delta_object, :delta_stages
    
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
      @name         = self.class.name_for model
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
    
    def core_name
      "#{name}_core"
    end
    
    def delta_name(stage)
      "#{name}_delta_#{stage}"
    end
    
    def delta_names
      @delta_object.stages.collect{|s| delta_name(s)}
    end
    
    def enumerate_delta_names
      delta_names.each{|n| yield(n)}
    end
    
    def all_names
      names  = [core_name]
      names += delta_names if delta?
      
      names
    end
    
    def self.name_for(model)
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
      all_index_options = config.index_options.clone
      @options.keys.select { |key|
        ThinkingSphinx::Configuration::IndexOptions.include?(key.to_s) ||
        ThinkingSphinx::Configuration::CustomOptions.include?(key.to_s)
      }.each { |key| all_index_options[key.to_sym] = @options[key] }
      all_index_options
    end
    
    def delta?
      !@delta_object.nil?
    end
    
    def to_riddle(offset)
      indexes = [to_riddle_for_core(offset)]
      @delta_object.stages.each {|s| indexes << to_riddle_for_delta(offset, s)} if delta?
      indexes << to_riddle_for_distributed
    end
    
    private
    
    def adapter
      @adapter ||= @model.sphinx_database_adapter
    end
    
    def utf8?
      options[:charset_type] == "utf-8"
    end
    
    def sql_query_pre_for_delta
      [""]
    end
    
    def config
      @config ||= ThinkingSphinx::Configuration.instance
    end
    
    def to_riddle_for_core(offset)
      index = Riddle::Configuration::Index.new core_name
      index.path = File.join config.searchd_file_path, index.name
      
      set_configuration_options_for_indexes index
      set_field_settings_for_indexes        index
      
      sources.each_with_index do |source, i|
        index.sources << source.to_riddle_for_core(offset, i)
      end
      
      index
    end
    
    def to_riddle_for_delta(offset, stage)
      index = Riddle::Configuration::Index.new delta_name(stage)
      index.parent = core_name
      index.path = File.join config.searchd_file_path, index.name
      
      sources.each_with_index do |source, i|
        index.sources << source.to_riddle_for_delta(offset, i, stage)
      end
      
      index
    end
    
    def to_riddle_for_distributed
      index = Riddle::Configuration::DistributedIndex.new name
      index.local_indexes << core_name 
      enumerate_delta_names {|n| index.local_indexes.unshift n} if delta?
      index
    end
    
    def set_configuration_options_for_indexes(index)
      config.index_options.each do |key, value|
        method = "#{key}=".to_sym
        index.send(method, value) if index.respond_to?(method)
      end
      
      options.each do |key, value|
        index.send("#{key}=".to_sym, value) if ThinkingSphinx::Configuration::IndexOptions.include?(key.to_s) && !value.nil?
      end
    end
    
    def set_field_settings_for_indexes(index)
      field_names = lambda { |field| field.unique_name.to_s }
      
      index.prefix_field_names += prefix_fields.collect(&field_names)
      index.infix_field_names  += infix_fields.collect(&field_names)
    end
  end
end
