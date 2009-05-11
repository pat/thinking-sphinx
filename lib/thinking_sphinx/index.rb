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
      
      # add_internal_attributes_and_facets
      
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
    
    def crc_column
      if @model.column_names.include?(@model.inheritance_column)
        adapter.cast_to_unsigned(adapter.convert_nulls(
          adapter.crc(adapter.quote_with_table(@model.inheritance_column), true),
          @model.to_crc32
        ))
      else
        @model.to_crc32.to_s
      end
    end
    
    def add_internal_attributes_and_facets
      add_internal_attribute :sphinx_internal_id, :integer, @model.primary_key.to_sym
      add_internal_attribute :class_crc,          :integer, crc_column, true
      add_internal_attribute :subclass_crcs,      :multi,   subclasses_to_s
      add_internal_attribute :sphinx_deleted,     :integer, "0"
      
      add_internal_facet :class_crc
    end
    
    def add_internal_attribute(name, type, contents, facet = false)
      return unless attribute_by_alias(name).nil?
      
      @attributes << Attribute.new(
        FauxColumn.new(contents),
        :type   => type,
        :as     => name,
        :facet  => facet,
        :admin  => true
      )
    end
    
    def add_internal_facet(name)
      return unless facet_by_alias(name).nil?
      
      @model.sphinx_facets << ClassFacet.new(attribute_by_alias(name))
    end
    
    def attribute_by_alias(attr_alias)
      @attributes.detect { |attrib| attrib.alias == attr_alias }
    end
    
    def facet_by_alias(name)
      @model.sphinx_facets.detect { |facet| facet.name == name }
    end
    
    def subclasses_to_s
      "'" + (@model.send(:subclasses).collect { |klass|
        klass.to_crc32.to_s
      } << @model.to_crc32.to_s).join(",") + "'"
    end
    
    def sql_query_pre_for_delta
      [""]
    end
  end
end
