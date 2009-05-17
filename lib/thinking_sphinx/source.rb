module ThinkingSphinx
  class Source
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
    
    # Generates the big SQL statement to get the data back for all the fields
    # and attributes, using all the relevant association joins. If you want
    # the version filtered for delta values, send through :delta => true in the
    # options. Won't do much though if the index isn't set up to support a
    # delta sibling.
    # 
    # Examples:
    # 
    #   source.to_sql
    #   source.to_sql(:delta => true)
    #
    def to_sql(options={})
      sql = <<-SQL
SELECT #{ sql_select_clause options[:offset] }
FROM #{ @model.quoted_table_name }
  #{ all_associations.collect { |assoc| assoc.to_sql }.join(' ') }
WHERE #{ sql_where_clause(options) }
GROUP BY #{ sql_group_clause }
      SQL

      sql += " ORDER BY NULL" if adapter.sphinx_identifier == "mysql"
      sql
    end
    
    # Simple helper method for the query range SQL - which is a statement that
    # returns minimum and maximum id values. These can be filtered by delta -
    # so pass in :delta => true to get the delta version of the SQL.
    # 
    def to_sql_query_range(options={})
      min_statement = adapter.convert_nulls(
        "MIN(#{quote_column(@model.primary_key)})", 1
      )
      max_statement = adapter.convert_nulls(
        "MAX(#{quote_column(@model.primary_key)})", 1
      )
      
      sql = "SELECT #{min_statement}, #{max_statement} " +
            "FROM #{@model.quoted_table_name} "
      if self.delta? && !@index.delta_object.clause(@model, options[:delta]).blank?
        sql << "WHERE #{@index.delta_object.clause(@model, options[:delta])}"
      end
      
      sql
    end
    
    # Simple helper method for the query info SQL - which is a statement that
    # returns the single row for a corresponding id.
    # 
    def to_sql_query_info(offset)
      "SELECT * FROM #{@model.quoted_table_name} WHERE " +
      "#{quote_column(@model.primary_key)} = (($id - #{offset}) / #{ThinkingSphinx.indexed_models.size})"
    end
    
    def sql_select_clause(offset)
      unique_id_expr = ThinkingSphinx.unique_id_expression(offset)
      
      (
        ["#{@model.quoted_table_name}.#{quote_column(@model.primary_key)} #{unique_id_expr} AS #{quote_column(@model.primary_key)} "] + 
        @fields.collect     { |field|     field.to_select_sql     } +
        @attributes.collect { |attribute| attribute.to_select_sql }
      ).compact.join(", ")
    end
    
    def sql_where_clause(options)
      logic = [
        "#{@model.quoted_table_name}.#{quote_column(@model.primary_key)} >= $start",
        "#{@model.quoted_table_name}.#{quote_column(@model.primary_key)} <= $end"
      ]
      
      if self.delta? && !@index.delta_object.clause(@model, options[:delta]).blank?
        logic << "#{@index.delta_object.clause(@model, options[:delta])}"
      end
      
      logic += (@conditions || [])
      
      logic.join(" AND ")
    end
    
    def sql_group_clause
      internal_groupings = []
      if @model.column_names.include?(@model.inheritance_column)
         internal_groupings << "#{@model.quoted_table_name}.#{quote_column(@model.inheritance_column)}"
      end
      
      (
        ["#{@model.quoted_table_name}.#{quote_column(@model.primary_key)}"] + 
        @fields.collect     { |field|     field.to_group_sql     }.compact +
        @attributes.collect { |attribute| attribute.to_group_sql }.compact +
        @groupings + internal_groupings
      ).join(", ")
    end
    
    def sql_query_pre_for_core
      if self.delta? && !@index.delta_object.reset_query(@model).blank?
        [@index.delta_object.reset_query(@model)]
      else
        []
      end
    end
    
    def sql_query_pre_for_delta
      [""]
    end
    
    def quote_column(column)
      @model.connection.quote_column_name(column)
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
      
      Attribute.new(self,
        ThinkingSphinx::Index::FauxColumn.new(contents),
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
  end
end
