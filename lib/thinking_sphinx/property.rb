module ThinkingSphinx
  class Property
    attr_accessor :alias, :columns, :associations, :model, :faceted, :admin
    
    def initialize(columns, options = {})
      @columns      = Array(columns)
      @associations = {}

      raise "Cannot define a field with no columns. Maybe you are trying to index a field with a reserved name (id, name). You can fix this error by using a symbol rather than a bare name (:id instead of id)." if @columns.empty? || @columns.any? { |column| !column.respond_to?(:__stack) }
      
      @alias    = options[:as]
      @faceted  = options[:facet]
      @admin    = options[:admin]
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
    
    def to_facet
      return nil unless @faceted
      
      ThinkingSphinx::Facet.new(self)
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
    
    private
    
    # Could there be more than one value related to the parent record? If so,
    # then this will return true. If not, false. It's that simple.
    # 
    def is_many?
      associations.values.flatten.any? { |assoc| assoc.is_many? }
    end
    
    # Returns true if any of the columns are string values, instead of database
    # column references.
    def is_string?
      columns.all? { |col| col.is_string? }
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
          "#{quote_with_table(assoc.join.aliased_table_name, column.__name)}" :
          nil
        }.compact.join(', ')
      end
    end
  end
end