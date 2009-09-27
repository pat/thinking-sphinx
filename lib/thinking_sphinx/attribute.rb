module ThinkingSphinx
  # Attributes - eternally useful when it comes to filtering, sorting or
  # grouping. This class isn't really useful to you unless you're hacking
  # around with the internals of Thinking Sphinx - but hey, don't let that
  # stop you.
  #
  # One key thing to remember - if you're using the attribute manually to
  # generate SQL statements, you'll need to set the base model, and all the
  # associations. Which can get messy. Use Index.link!, it really helps.
  # 
  class Attribute < ThinkingSphinx::Property
    attr_accessor :query_source
    
    # To create a new attribute, you'll need to pass in either a single Column
    # or an array of them, and some (optional) options.
    #
    # Valid options are:
    # - :as     => :alias_name
    # - :type   => :attribute_type
    # - :source => :field, :query, :ranged_query
    #
    # Alias is only required in three circumstances: when there's
    # another attribute or field with the same name, when the column name is
    # 'id', or when there's more than one column.
    # 
    # Type is not required, unless you want to force a column to be a certain
    # type (but keep in mind the value will not be CASTed in the SQL
    # statements). The only time you really need to use this is when the type
    # can't be figured out by the column - ie: when not actually using a
    # database column as your source.
    # 
    # Source is only used for multi-value attributes (MVA). By default this will
    # use a left-join and a group_concat to obtain the values. For better performance
    # during indexing it can be beneficial to let Sphinx use a separate query to retrieve
    # all document,value-pairs.
    # Either :query or :ranged_query will enable this feature, where :ranged_query will cause
    # the query to be executed incremental.
    #
    # Example usage:
    #
    #   Attribute.new(
    #     Column.new(:created_at)
    #   )
    #
    #   Attribute.new(
    #     Column.new(:posts, :id),
    #     :as => :post_ids
    #   )
    #
    #   Attribute.new(
    #     Column.new(:posts, :id),
    #     :as => :post_ids,
    #     :source => :ranged_query
    #   )
    #
    #   Attribute.new(
    #     [Column.new(:pages, :id), Column.new(:articles, :id)],
    #     :as => :content_ids
    #   )
    #
    #   Attribute.new(
    #     Column.new("NOW()"),
    #     :as   => :indexed_at,
    #     :type => :datetime
    #   )
    #
    # If you're creating attributes for latitude and longitude, don't forget
    # that Sphinx expects these values to be in radians.
    #  
    def initialize(source, columns, options = {})
      super
      
      @type           = options[:type]
      @query_source   = options[:source]
      @crc            = options[:crc]
      
      @type         ||= :multi    unless @query_source.nil?
      if @type == :string && @crc
        @type = is_many? ? :multi : :integer
      end
      
      source.attributes << self
    end
    
    # Get the part of the SELECT clause related to this attribute. Don't forget
    # to set your model and associations first though.
    #
    # This will concatenate strings and arrays of integers, and convert
    # datetimes to timestamps, as needed.
    # 
    def to_select_sql
      return nil unless include_as_association?
      
      separator = all_ints? || all_datetimes? || @crc ? ',' : ' '
      
      clause = @columns.collect { |column|
        part = column_with_prefix(column)
        case type
        when :string
          adapter.convert_nulls(part)
        when :datetime
          adapter.cast_to_datetime(part)
        when :multi
          adapter.convert_nulls(part, 0)
        else
          part
        end
      }.join(', ')
      
      # clause = adapter.cast_to_datetime(clause)             if type == :datetime
      clause = adapter.crc(clause)                          if @crc
      clause = adapter.concatenate(clause, separator)       if concat_ws?
      clause = adapter.group_concatenate(clause, separator) if is_many?
      
      "#{clause} AS #{quote_column(unique_name)}"
    end
    
    def type_to_config
      {
        :multi    => :sql_attr_multi,
        :datetime => :sql_attr_timestamp,
        :string   => :sql_attr_str2ordinal,
        :float    => :sql_attr_float,
        :boolean  => :sql_attr_bool,
        :integer  => :sql_attr_uint
      }[type]
    end
    
    def include_as_association?
      ! (type == :multi && (query_source == :query || query_source == :ranged_query))
    end
    
    # Returns the configuration value that should be used for
    # the attribute.
    # Special case is the multi-valued attribute that needs some
    # extra configuration. 
    # 
    def config_value(offset = nil, delta = false)
      if type == :multi
        multi_config = include_as_association? ? "field" :
          source_value(offset, delta).gsub(/\s+/m, " ").strip
        "uint #{unique_name} from #{multi_config}"
      else
        unique_name
      end
    end
        
    # Returns the type of the column. If that's not already set, it returns
    # :multi if there's the possibility of more than one value, :string if
    # there's more than one association, otherwise it figures out what the
    # actual column's datatype is and returns that.
    # 
    def type
      @type ||= begin
        base_type = case
        when is_many_datetimes?
          :datetime
        when is_many?, is_many_ints?
          :multi
        when @associations.values.flatten.length > 1
          :string
        else
          translated_type_from_database
        end
        
        if base_type == :string && @crc
          base_type = :integer
        else
          @crc = false unless base_type == :multi && is_many_strings? && @crc
        end
        
        base_type
      end
    end
    
    def updatable?
      [:integer, :datetime, :boolean].include?(type) && !is_string?
    end
    
    def live_value(instance)
      object = instance
      column = @columns.first
      column.__stack.each { |method| object = object.send(method) }
      object.send(column.__name)
    end
    
    def all_ints?
      all_of_type?(:integer)
    end
    
    def all_datetimes?
      all_of_type?(:datetime, :date, :timestamp)
    end
    
    def all_strings?
      all_of_type?(:string, :text)
    end
    
    private
    
    def source_value(offset, delta)
      if is_string?
        return "#{query_source.to_s.dasherize}; #{columns.first.__name}"
      end
      
      query = query(offset)

      if query_source == :ranged_query
        query += query_clause
        query += " AND #{query_delta.strip}" if delta
        "ranged-query; #{query}; #{range_query}"
      else
        query += "WHERE #{query_delta.strip}" if delta
        "query; #{query}"
      end
    end
    
    def query(offset)
      base_assoc = base_association_for_mva
      end_assoc  = end_association_for_mva
      raise "Could not determine SQL for MVA" if base_assoc.nil?
      
      <<-SQL
SELECT #{foreign_key_for_mva base_assoc}
  #{ThinkingSphinx.unique_id_expression(offset)} AS #{quote_column('id')},
  #{primary_key_for_mva(end_assoc)} AS #{quote_column(unique_name)}
FROM #{quote_table_name base_assoc.table} #{association_joins}
      SQL
    end
    
    def query_clause
      foreign_key = foreign_key_for_mva base_association_for_mva
      "WHERE #{foreign_key} >= $start AND #{foreign_key} <= $end"
    end
    
    def query_delta
      foreign_key = foreign_key_for_mva base_association_for_mva
      <<-SQL
#{foreign_key} IN (SELECT #{quote_column model.primary_key}
FROM #{model.quoted_table_name}
WHERE #{@source.index.delta_object.clause(model, true)})
      SQL
    end
    
    def range_query
      assoc       = base_association_for_mva
      foreign_key = foreign_key_for_mva assoc
      "SELECT MIN(#{foreign_key}), MAX(#{foreign_key}) FROM #{quote_table_name assoc.table}"
    end
    
    def primary_key_for_mva(assoc)
      quote_with_table(
        assoc.table, assoc.primary_key_from_reflection || columns.first.__name
      )
    end
    
    def foreign_key_for_mva(assoc)
      quote_with_table assoc.table, assoc.reflection.primary_key_name
    end
    
    def end_association_for_mva
      @association_for_mva ||= associations[columns.first].detect { |assoc|
        assoc.has_column?(columns.first.__name)
      }
    end
    
    def base_association_for_mva
      @first_association_for_mva ||= begin
        assoc = end_association_for_mva
        while !assoc.parent.nil?
          assoc = assoc.parent
        end
        
        assoc
      end
    end
    
    def association_joins
      joins = []
      assoc = end_association_for_mva
      while assoc != base_association_for_mva
        joins << assoc.to_sql
        assoc = assoc.parent
      end
      
      joins.join(' ')
    end
    
    def is_many_ints?
      concat_ws? && all_ints?
    end
    
    def is_many_datetimes?
      is_many? && all_datetimes?
    end
    
    def is_many_strings?
      is_many? && all_strings?
    end
       
    def type_from_database
      klass = @associations.values.flatten.first ? 
        @associations.values.flatten.first.reflection.klass : @model
      
      column = klass.columns.detect { |col|
        @columns.collect { |c| c.__name.to_s }.include? col.name
      }
      column.nil? ? nil : column.type
    end
    
    def translated_type_from_database
      case type_from_db = type_from_database
      when :datetime, :string, :float, :boolean, :integer
        type_from_db
      when :decimal
        :float
      when :timestamp, :date
        :datetime
      else
        raise <<-MESSAGE

Cannot automatically map attribute #{unique_name} in #{@model.name} to an
equivalent Sphinx type (integer, float, boolean, datetime, string as ordinal).
You could try to explicitly convert the column's value in your define_index
block:
  has "CAST(column AS INT)", :type => :integer, :as => :column
        MESSAGE
      end
    end
    
    def all_of_type?(*column_types)
      @columns.all? { |col|
        klasses = @associations[col].empty? ? [@model] :
          @associations[col].collect { |assoc| assoc.reflection.klass }
        klasses.all? { |klass|
          column = klass.columns.detect { |column| column.name == col.__name.to_s }
          !column.nil? && column_types.include?(column.type)
        }
      }
    end
  end
end