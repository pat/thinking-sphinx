module ThinkingSphinx
  # Fields - holding the string data which Sphinx indexes for your searches.
  # This class isn't really useful to you unless you're hacking around with the
  # internals of Thinking Sphinx - but hey, don't let that stop you.
  #
  # One key thing to remember - if you're using the field manually to
  # generate SQL statements, you'll need to set the base model, and all the
  # associations. Which can get messy. Use Index.link!, it really helps.
  # 
  class Field < ThinkingSphinx::Property
    attr_accessor :sortable, :infixes, :prefixes
    
    # To create a new field, you'll need to pass in either a single Column
    # or an array of them, and some (optional) options. The columns are
    # references to the data that will make up the field.
    #
    # Valid options are:
    # - :as       => :alias_name 
    # - :sortable => true
    # - :infixes  => true
    # - :prefixes => true
    # - :file     => true
    # - :with     => :attribute # or :wordcount
    #
    # Alias is only required in three circumstances: when there's
    # another attribute or field with the same name, when the column name is
    # 'id', or when there's more than one column.
    # 
    # Sortable defaults to false - but is quite useful when set to true, as
    # it creates an attribute with the same string value (which Sphinx converts
    # to an integer value), which can be sorted by. Thinking Sphinx is smart
    # enough to realise that when you specify fields in sort statements, you
    # mean their respective attributes.
    # 
    # If you have partial matching enabled (ie: enable_star), then you can
    # specify certain fields to have their prefixes and infixes indexed. Keep
    # in mind, though, that Sphinx's default is _all_ fields - so once you
    # highlight a particular field, no other fields in the index will have
    # these partial indexes.
    #
    # Here's some examples:
    #
    #   Field.new(
    #     Column.new(:name)
    #   )
    #
    #   Field.new(
    #     [Column.new(:first_name), Column.new(:last_name)],
    #     :as => :name, :sortable => true
    #   )
    # 
    #   Field.new(
    #     [Column.new(:posts, :subject), Column.new(:posts, :content)],
    #     :as => :posts, :prefixes => true
    #   )
    # 
    def initialize(source, columns, options = {})
      super
      
      @sortable = options[:sortable] || false
      @infixes  = options[:infixes]  || false
      @prefixes = options[:prefixes] || false
      @file     = options[:file]     || false
      @with     = options[:with]
      
      source.fields << self
    end
    
    # Get the part of the SELECT clause related to this field. Don't forget
    # to set your model and associations first though.
    #
    # This will concatenate strings if there's more than one data source or
    # multiple data values (has_many or has_and_belongs_to_many associations).
    # 
    def to_select_sql
      return nil unless available?
      
      clause = columns_with_prefixes.join(', ')
      
      clause = adapter.concatenate(clause)       if concat_ws?
      clause = adapter.group_concatenate(clause) if is_many?
      
      "#{clause} AS #{quote_column(unique_name)}"
    end
    
    def file?
      @file
    end
    
    def with_attribute?
      @with == :attribute
    end
    
    def with_wordcount?
      @with == :wordcount
    end
  end
end
