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
  class Attribute
    attr_accessor :alias, :columns, :associations, :model, :faceted, :source
    
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
    def initialize(columns, options = {})
      @columns      = Array(columns)
      @associations = {}
      
      raise "Cannot define a field with no columns. Maybe you are trying to index a field with a reserved name (id, name). You can fix this error by using a symbol rather than a bare name (:id instead of id)." if @columns.empty? || @columns.any? { |column| !column.respond_to?(:__stack) }
      
      @alias    = options[:as]
      @type     = options[:type]
      @faceted  = options[:facet]
      @source   = options[:source]
      
      @type   ||= :multi unless @source.nil?
    end
    
    # Get the part of the SELECT clause related to this attribute. Don't forget
    # to set your model and associations first though.
    #
    # This will concatenate strings and arrays of integers, and convert
    # datetimes to timestamps, as needed.
    # 
    def to_select_sql
      return nil unless include_as_association?
      
      clause = @columns.collect { |column|
        column_with_prefix(column)
      }.join(', ')
      
      separator = all_ints? ? ',' : ' '
      
      clause = adapter.concatenate(clause, separator)       if concat_ws?
      clause = adapter.group_concatenate(clause, separator) if is_many?
      clause = adapter.cast_to_datetime(clause)             if type == :datetime
      clause = adapter.convert_nulls(clause)                if type == :string
      
      "#{clause} AS #{quote_column(unique_name)}"
    end
    
    # Get the part of the GROUP BY clause related to this attribute - if one is
    # needed. If not, all you'll get back is nil. The latter will happen if
    # there isn't actually a real column to get data from, or if there's
    # multiple data values (read: a has_many or has_and_belongs_to_many
    # association).
    # 
    def to_group_sql
      case
      when is_many?, is_string?, ThinkingSphinx.use_group_by_shortcut?
        nil
      else
        @columns.collect { |column|
          column_with_prefix(column)
        }
      end
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
      ! (type == :multi && (source == :query || source == :ranged_query))
    end
    
    # Returns the configuration value that should be used for
    # the attribute.
    # Special case is the multi-valued attribute that needs some
    # extra configuration. 
    # 
    def config_value(offset = nil)
      if type == :multi
        multi_config = include_as_association? ? "field" :
          source_value(offset).gsub(/\n\s*/, " ")
        "uint #{unique_name} from #{multi_config}"
      else
        unique_name
      end
    end
    
    # Returns the unique name of the attribute - which is either the alias of
    # the attribute, or the name of the only column - if there is only one. If
    # there isn't, there should be an alias. Else things probably won't work.
    # Consider yourself warned.
    # 
    def unique_name
      if @columns.length == 1
        @alias || @columns.first.__name
      else
        @alias
      end
    end
    
    # Returns the type of the column. If that's not already set, it returns
    # :multi if there's the possibility of more than one value, :string if
    # there's more than one association, otherwise it figures out what the
    # actual column's datatype is and returns that.
    def type
      @type ||= case
      when is_many?, is_many_ints?
        :multi
      when @associations.values.flatten.length > 1
        :string
      else
        translated_type_from_database
      end
    end
    
    def to_facet
      return nil unless @faceted
      
      ThinkingSphinx::Facet.new(self)
    end
    
    private
    
    def source_value(offset)
      if is_string?
        "#{source.to_s.dasherize}; #{columns.first.__name}"
      elsif source == :ranged_query
        "ranged-query; #{query offset} #{query_clause}; #{range_query}"
      else
        "query; #{query offset}"
      end
    end
    
    def query(offset)
      assoc = association_for_mva
      raise "Could not determine SQL for MVA" if assoc.nil?
      
      <<-SQL
SELECT #{foreign_key_for_mva assoc}
  #{ThinkingSphinx.unique_id_expression(offset)} AS #{quote_column('id')},
  #{primary_key_for_mva(assoc)} AS #{quote_column(unique_name)}
FROM #{quote_table_name assoc.table}
      SQL
    end
    
    def query_clause
      foreign_key = foreign_key_for_mva association_for_mva
      "WHERE #{foreign_key} >= $start AND #{foreign_key} <= $end"
    end
    
    def range_query
      assoc       = association_for_mva
      foreign_key = foreign_key_for_mva assoc
      "SELECT MIN(#{foreign_key}), MAX(#{foreign_key assoc}) FROM #{quote_table_name assoc.table}"
    end
    
    def primary_key_for_mva(assoc)
      quote_with_table(
        assoc.table, assoc.primary_key_from_reflection || columns.first.__name
      )
    end
    
    def foreign_key_for_mva(assoc)
      quote_with_table assoc.table, assoc.reflection.primary_key_name
    end
    
    def association_for_mva
      @association_for_mva ||= associations[columns.first].detect { |assoc|
        assoc.has_column?(columns.first.__name)
      }
    end
    
    def adapter
      @adapter ||= @model.sphinx_database_adapter
    end
    
    def quote_with_table(table, column)
      "#{quote_table_name(table)}.#{quote_column(column)}"
    end
    
    def quote_column(column)
      @model.connection.quote_column_name(column)
    end
    
    def quote_table_name(table_name)
      @model.connection.quote_table_name(table_name)
    end
    
    # Indication of whether the columns should be concatenated with a space
    # between each value. True if there's either multiple sources or multiple
    # associations.
    # 
    def concat_ws?
      multiple_associations? || @columns.length > 1
    end
        
    # Checks whether any column requires multiple associations (which only
    # happens for polymorphic situations).
    # 
    def multiple_associations?
      associations.any? { |col,assocs| assocs.length > 1 }
    end
    
    # Builds a column reference tied to the appropriate associations. This
    # dives into the associations hash and their corresponding joins to
    # figure out how to correctly reference a column in SQL.
    # 
    def column_with_prefix(column)
      if column.is_string?
        column.__name
      elsif associations[column].empty?
        "#{@model.quoted_table_name}.#{quote_column(column.__name)}"
      else
        associations[column].collect { |assoc|
          assoc.has_column?(column.__name) ?
          "#{quote_table_name(assoc.join.aliased_table_name)}" + 
          ".#{quote_column(column.__name)}" :
          nil
        }.compact.join(', ')
      end
    end
    
    # Could there be more than one value related to the parent record? If so,
    # then this will return true. If not, false. It's that simple.
    # 
    def is_many?
      associations.values.flatten.any? { |assoc| assoc.is_many? }
    end
    
    def is_many_ints?
      concat_ws? && all_ints?
    end
    
    # Returns true if any of the columns are string values, instead of database
    # column references.
    def is_string?
      columns.all? { |col| col.is_string? }
    end
    
    def all_ints?
      @columns.all? { |col|
        klasses = @associations[col].empty? ? [@model] :
          @associations[col].collect { |assoc| assoc.reflection.klass }
        klasses.all? { |klass|
          column = klass.columns.detect { |column| column.name == col.__name.to_s }
          !column.nil? && column.type == :integer
        }
      }
    end
    
    def type_from_database
      klass = @associations.values.flatten.first ? 
        @associations.values.flatten.first.reflection.klass : @model
      
      klass.columns.detect { |col|
        @columns.collect { |c| c.__name.to_s }.include? col.name
      }.type
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

Cannot automatically map column type #{type_from_db} to an equivalent Sphinx
type (integer, float, boolean, datetime, string as ordinal). You could try to
explicitly convert the column's value in your define_index block:
  has "CAST(column AS INT)", :type => :integer, :as => :column
        MESSAGE
      end
    end
  end
end