require 'thinking_sphinx/source/internal_properties'
require 'thinking_sphinx/source/sql'

module ThinkingSphinx
  class Source
    include ThinkingSphinx::Source::InternalProperties
    include ThinkingSphinx::Source::SQL
    
    attr_accessor :model, :fields, :attributes, :conditions, :groupings,
      :options
    attr_reader :base
    
    def initialize(index, options = {})
      @index        = index
      @model        = index.model
      @fields       = []
      @attributes   = []
      @conditions   = []
      @groupings    = []
      @options      = options
      @associations = {}
      
      @base = ::ActiveRecord::Associations::ClassMethods::JoinDependency.new(
        @model, [], nil
      )
      
      unless @model.descends_from_active_record?
        stored_class = @model.store_full_sti_class ? @model.name : @model.name.demodulize
        @conditions << "#{@model.quoted_table_name}.#{quote_column(@model.inheritance_column)} = '#{stored_class}'"
      end
      
      add_internal_attributes_and_facets
    end
    
    def name
      @model.name.underscore.tr(':/\\', '_')
    end
    
    def to_riddle_for_core(offset, index)
      source = Riddle::Configuration::SQLSource.new(
        "#{name}_core_#{index}", adapter.sphinx_identifier
      )
      
      set_source_database_settings  source
      set_source_attributes         source, offset
      set_source_sql                source, offset
      set_source_settings           source
      
      source
    end
    
    def to_riddle_for_delta(offset, index)
      source = Riddle::Configuration::SQLSource.new(
        "#{name}_delta_#{index}", adapter.sphinx_identifier
      )
      source.parent = "#{name}_core_#{index}"
      
      set_source_database_settings  source
      set_source_attributes         source, offset
      set_source_sql                source, offset, true
      
      source
    end
    
    def delta?
      !@index.delta_object.nil?
    end
    
    # Gets the association stack for a specific key.
    # 
    def association(key)
      @associations[key] ||= Association.children(@model, key)
    end
    
    private
    
    def adapter
      @adapter ||= @model.sphinx_database_adapter
    end
    
    def set_source_database_settings(source)
      config = @model.connection.instance_variable_get(:@config)
      
      source.sql_host = config[:host]           || "localhost"
      source.sql_user = config[:username]       || config[:user] || ""
      source.sql_pass = (config[:password].to_s || "").gsub('#', '\#')
      source.sql_db   = config[:database]
      source.sql_port = config[:port]
      source.sql_sock = config[:socket]
    end
    
    def set_source_attributes(source, offset)
      attributes.each do |attrib|
        source.send(attrib.type_to_config) << attrib.config_value(offset)
      end
    end
    
    def set_source_sql(source, offset, delta = false)
      source.sql_query        = to_sql(:offset => offset, :delta => delta).gsub(/\n/, ' ')
      source.sql_query_range  = to_sql_query_range(:delta => delta)
      source.sql_query_info   = to_sql_query_info(offset)
      
      source.sql_query_pre += send(!delta ? :sql_query_pre_for_core : :sql_query_pre_for_delta)
      
      if @options[:group_concat_max_len]
        source.sql_query_pre << "SET SESSION group_concat_max_len = #{@options[:group_concat_max_len]}"
      end
      
      source.sql_query_pre += [adapter.utf8_query_pre].compact if utf8?
    end
    
    def set_source_settings(source)
      config = ThinkingSphinx::Configuration.instance
      config.source_options.each do |key, value|
        source.send("#{key}=".to_sym, value)
      end
      
      source_options = ThinkingSphinx::Configuration::SourceOptions
      @options.each do |key, value|
        if source_options.include?(key.to_s) && !value.nil?
          source.send("#{key}=".to_sym, value)
        end
      end
    end
    
    # Returns all associations used amongst all the fields and attributes.
    # This includes all associations between the model and what the actual
    # columns are from.
    # 
    def all_associations
      @all_associations ||= (
        # field associations
        @fields.collect { |field|
          field.associations.values
        }.flatten +
        # attribute associations
        @attributes.collect { |attrib|
          attrib.associations.values if attrib.include_as_association?
        }.compact.flatten
      ).uniq.collect { |assoc|
        # get ancestors as well as column-level associations
        assoc.ancestors
      }.flatten.uniq
    end
    
    def utf8?
      @index.options[:charset_type] == "utf-8"
    end
  end
end
