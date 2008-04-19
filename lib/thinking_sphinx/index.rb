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
    attr_accessor :model, :fields, :attributes, :conditions, :delta, :options
    
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
      @associations = {}
      @fields       = []
      @attributes   = []
      @conditions   = []
      @options      = {}
      @delat        = false
      
      initialize_from_builder(&block) if block_given?
    end
    
    # Link all the fields and associations to their corresponding
    # associations and joins. This _must_ be called before interrogating
    # the index's fields and associations for anything that may reference
    # their SQL structure.
    # 
    def link!
      base = ::ActiveRecord::Associations::ClassMethods::JoinDependency.new(
        @model, [], nil
      )
      
      @fields.each { |field|
        field.model ||= @model
        field.columns.each { |col|
          field.associations[col] = associations(col.__stack.clone)
          field.associations[col].each { |assoc| assoc.join_to(base) }
        }
      }
      
      @attributes.each { |attribute|
        attribute.model ||= @model
        attribute.columns.each { |col|
          attribute.associations[col] = associations(col.__stack.clone)
          attribute.associations[col].each { |assoc| assoc.join_to(base) }
        }
      }
    end
    
    # Generates the big SQL statement to get the data back for all the fields
    # and attributes, using all the relevant association joins. If you want
    # the version filtered for delta values, send through :delta => true in the
    # options. Won't do much though if the index isn't set up to support a
    # delta sibling.
    # 
    # Examples:
    # 
    #   index.to_sql
    #   index.to_sql(:delta => true)
    #
    def to_sql(options={})
      assocs = all_associations
      
      where_clause = ""
      if self.delta?
        where_clause << " AND `#{@model.table_name}`.`delta` = #{options[:delta] ? 1 : 0}"
      end
      unless @conditions.empty?
        where_clause << " AND " << @conditions.join(" AND ")
      end
      
      <<-SQL
SELECT #{ (
  ["`#{@model.table_name}`.`#{@model.primary_key}`"] + 
  @fields.collect { |field| field.to_select_sql } +
  @attributes.collect { |attribute| attribute.to_select_sql }
).join(", ") }
FROM #{@model.table_name}
  #{ assocs.collect { |assoc| assoc.to_sql }.join(' ') }
WHERE `#{@model.table_name}`.`#{@model.primary_key}` >= $start
  AND `#{@model.table_name}`.`#{@model.primary_key}` <= $end
  #{ where_clause }
GROUP BY #{ (
  ["`#{@model.table_name}`.`#{@model.primary_key}`"] + 
  @fields.collect { |field| field.to_group_sql }.compact +
  @attributes.collect { |attribute| attribute.to_group_sql }.compact
).join(", ") }
ORDER BY NULL
      SQL
    end
    
    # Simple helper method for the query info SQL - which is a statement that
    # returns the single row for a corresponding id.
    # 
    def to_sql_query_info
      "SELECT * FROM `#{@model.table_name}` WHERE `#{@model.primary_key}` = $id"
    end
    
    # Simple helper method for the query range SQL - which is a statement that
    # returns minimum and maximum id values. These can be filtered by delta -
    # so pass in :delta => true to get the delta version of the SQL.
    # 
    def to_sql_query_range(options={})
      sql = "SELECT MIN(`#{@model.primary_key}`), MAX(`#{@model.primary_key}`) " +
            "FROM `#{@model.table_name}` "
      sql << "WHERE `#{@model.table_name}`.`delta` = #{options[:delta] ? 1 : 0}" if self.delta?
      sql
    end
    
    # Returns the SQL query to run before a full index - ie: nothing unless the
    # index has a delta, and then it's an update statement to set delta values
    # back to 0.
    #
    def to_sql_query_pre
      self.delta? ? "UPDATE `#{@model.table_name}` SET `delta` = 0" : ""
    end
    
    # Flag to indicate whether this index has a corresponding delta index.
    #
    def delta?
      @delta
    end
    
    private
    
    # Does all the magic with the block provided to the base #initialize.
    # Creates a new class subclassed from Builder, and evaluates the block
    # on it, then pulls all relevant settings - fields, attributes, conditions,
    # properties - into the new index.
    # 
    # Also creates a CRC attribute for the model.
    # 
    def initialize_from_builder(&block)
      builder = Class.new(Builder)
      builder.setup
      
      builder.instance_eval &block
      
      @fields     = builder.fields
      @attributes = builder.attributes
      @conditions = builder.conditions
      @delta      = builder.properties[:delta]
      @options    = builder.properties.except(:delta)
      
      @attributes << Attribute.new(
        FauxColumn.new(@model.to_crc32.to_s),
        :type => :integer,
        :as   => :class_crc
      )
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
          attrib.associations.values
        }.flatten
      ).uniq.collect { |assoc|
        # get ancestors as well as column-level associations
        assoc.ancestors
      }.flatten.uniq
    end
    
    # Gets a stack of associations for a specific path.
    # 
    def associations(path, parent = nil)
      assocs = []
      
      if parent.nil?
        assocs = association(path.shift)
      else
        assocs = parent.children(path.shift)
      end
      
      until path.empty?
        point = path.shift
        assocs = assocs.collect { |assoc|
          assoc.children(point)
        }.flatten
      end
      
      assocs
    end
    
    # Gets the association stack for a specific key.
    # 
    def association(key)
      @associations[key] ||= Association.children(@model, key)
    end
  end
end