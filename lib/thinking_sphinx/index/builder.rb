module ThinkingSphinx
  class Index
    # The Builder class is the core for the index definition block processing.
    # There are four methods you really need to pay attention to:
    # - indexes
    # - has
    # - where
    # - set_property/set_properties
    #
    # The first two of these methods allow you to define what data makes up
    # your indexes. #where provides a method to add manual SQL conditions, and
    # set_property allows you to set some settings on a per-index basis. Check
    # out each method's documentation for better ideas of usage.
    # 
    class Builder
      instance_methods.grep(/^[^_]/).each { |method|
        next if method.to_s == "instance_eval"
        define_method(method) {
          caller.grep(/irb.completion/).empty? ? method_missing(method) : super
        }
      }
      
      def self.generate(model, name = nil, &block)
        index  = ThinkingSphinx::Index.new(model)
        index.name = name unless name.nil?
        
        Builder.new(index, &block) if block_given?
        
        index.delta_object = ThinkingSphinx::Deltas.parse index
        index
      end
      
      def initialize(index, &block)
        @index  = index
        @explicit_source = false
        
        self.instance_eval &block
        
        if no_fields?
          raise "At least one field is necessary for an index"
        end
      end
      
      def define_source(&block)
        if @explicit_source
          @source = ThinkingSphinx::Source.new(@index)
          @index.sources << @source
        else
          @explicit_source = true
        end
        
        self.instance_eval &block
      end
      
      # This is how you add fields - the strings Sphinx looks at - to your
      # index. Technically, to use this method, you need to pass in some
      # columns and options - but there's some neat method_missing stuff
      # happening, so lets stick to the expected syntax within a define_index
      # block.
      #
      # Expected options are :as, which points to a column alias in symbol
      # form, and :sortable, which indicates whether you want to sort by this
      # field.
      #
      # Adding Single-Column Fields:
      # 
      # You can use symbols or methods - and can chain methods together to
      # get access down the associations tree.
      # 
      #   indexes :id, :as => :my_id
      #   indexes :name, :sortable => true
      #   indexes first_name, last_name, :sortable => true
      #   indexes users.posts.content, :as => :post_content
      #   indexes users(:id), :as => :user_ids
      #
      # Keep in mind that if any keywords for Ruby methods - such as id or 
      # name - clash with your column names, you need to use the symbol
      # version (see the first, second and last examples above).
      #
      # If you specify multiple columns (example #2), a field will be created
      # for each. Don't use the :as option in this case. If you want to merge
      # those columns together, continue reading.
      # 
      # Adding Multi-Column Fields:
      # 
      #   indexes [first_name, last_name], :as => :name
      #   indexes [location, parent.location], :as => :location
      #
      # To combine multiple columns into a single field, you need to wrap
      # them in an Array, as shown by the above examples. There's no
      # limitations on whether they're symbols or methods or what level of
      # associations they come from.
      # 
      # Adding SQL Fragment Fields
      #
      # You can also define a field using an SQL fragment, useful for when
      # you would like to index a calculated value.
      #
      #   indexes "age < 18", :as => :minor
      #
      def indexes(*args)
        options = args.extract_options!
        args.each do |columns|
          field = Field.new(source, FauxColumn.coerce(columns), options)
          
          add_sort_attribute  field, options   if field.sortable
          add_facet_attribute field, options   if field.faceted
        end
      end
      
      # This is the method to add attributes to your index (hence why it is
      # aliased as 'attribute'). The syntax is the same as #indexes, so use
      # that as starting point, but keep in mind the following points.
      # 
      # An attribute can have an alias (the :as option), but it is always
      # sortable - so you don't need to explicitly request that. You _can_
      # specify the data type of the attribute (the :type option), but the
      # code's pretty good at figuring that out itself from peering into the
      # database.
      # 
      # Attributes are limited to the following types: integers, floats,
      # datetimes (converted to timestamps), booleans, strings and MVAs
      # (:multi). Don't forget that Sphinx converts string attributes to
      # integers, which are useful for sorting, but that's about it.
      # 
      # Collection of integers are known as multi-value attributes (MVAs).
      # Generally these would be through a has_many relationship, like in this
      # example:
      # 
      #   has posts(:id), :as => :post_ids
      # 
      # This allows you to filter on any of the values tied to a specific
      # record. Might be best to read through the Sphinx documentation to get
      # a better idea of that though.
      # 
      # Adding SQL Fragment Attributes
      #
      # You can also define an attribute using an SQL fragment, useful for
      # when you would like to index a calculated value. Don't forget to set
      # the type of the attribute though:
      #
      #   has "age < 18", :as => :minor, :type => :boolean
      # 
      # If you're creating attributes for latitude and longitude, don't
      # forget that Sphinx expects these values to be in radians.
      # 
      def has(*args)
        options = args.extract_options!
        args.each do |columns|
          attribute = Attribute.new(source, FauxColumn.coerce(columns), options)
          
          add_facet_attribute attribute, options if attribute.faceted
        end
      end
      
      def facet(*args)
        options = args.extract_options!
        options[:facet] = true
        
        args.each do |columns|
          attribute = Attribute.new(source, FauxColumn.coerce(columns), options)
          
          add_facet_attribute attribute, options
        end
      end
      
      def join(*args)
        args.each do |association|
          Join.new(source, association)
        end
      end
      
      # Use this method to add some manual SQL conditions for your index
      # request. You can pass in as many strings as you like, they'll get
      # joined together with ANDs later on.
      # 
      #   where "user_id = 10"
      #   where "parent_type = 'Article'", "created_at < NOW()"
      # 
      def where(*args)
        source.conditions += args
      end
      
      # Use this method to add some manual SQL strings to the GROUP BY
      # clause. You can pass in as many strings as you'd like, they'll get
      # joined together with commas later on.
      # 
      #   group_by "lat", "lng"
      # 
      def group_by(*args)
        source.groupings += args
      end
      
      # This is what to use to set properties on the index. Chief amongst
      # those is the delta property - to allow automatic updates to your
      # indexes as new models are added and edited - but also you can
      # define search-related properties which will be the defaults for all
      # searches on the model.
      # 
      #   set_property :delta => true
      #   set_property :field_weights => {"name" => 100}
      #   set_property :order => "name ASC"
      #   set_property :select => 'name'
      # 
      # Also, the following two properties are particularly relevant for
      # geo-location searching - latitude_attr and longitude_attr. If your
      # attributes for these two values are named something other than
      # lat/latitude or lon/long/longitude, you can dictate what they are
      # when defining the index, so you don't need to specify them for every
      # geo-related search.
      #
      #   set_property :latitude_attr => "lt", :longitude_attr => "lg"
      # 
      # Please don't forget to add a boolean field named 'delta' to your
      # model's database table if enabling the delta index for it.
      # Valid options for the delta property are:
      # 
      # true
      # false
      # :default
      # :delayed
      # :datetime
      # 
      # You can also extend ThinkingSphinx::Deltas::DefaultDelta to implement 
      # your own handling for delta indexing.
      # 
      def set_property(*args)
        options = args.extract_options!
        options.each do |key, value|
          set_single_property key, value
        end
        
        set_single_property args[0], args[1] if args.length == 2
      end
      alias_method :set_properties, :set_property
      
      # Handles the generation of new columns for the field and attribute
      # definitions.
      # 
      def method_missing(method, *args)
        FauxColumn.new(method, *args)
      end
      
      # A method to allow adding fields from associations which have names
      # that clash with method names in the Builder class (ie: properties,
      # fields, attributes).
      # 
      # Example: indexes assoc(:properties).column
      # 
      def assoc(assoc, *args)
        FauxColumn.new(assoc, *args)
      end
      
      # Use this method to generate SQL for your attributes, conditions, etc.
      # You can pass in whatever
      # ActiveRecord::Base.sanitize_sql_for_conditions accepts.
      # 
      #   where sanitize_sql_for_conditions(:active => true)
      #   #=> WHERE active = 1
      # 
      def sanitize_sql_for_conditions(condition)
        @index.model.send(:sanitize_sql_for_conditions, condition)
      end
      alias_method :sanitize_sql, :sanitize_sql_for_conditions

      private
      
      def source
        @source ||= begin
          source = ThinkingSphinx::Source.new(@index)
          @index.sources << source
          source
        end
      end
      
      def set_single_property(key, value)
        source_options = ThinkingSphinx::Configuration::SourceOptions
        if source_options.include?(key.to_s)
          source.options.merge! key => value
        else
          @index.local_options.merge!  key => value
        end
      end
      
      def add_sort_attribute(field, options)
        add_internal_attribute field, options, "_sort"
      end
      
      def add_facet_attribute(property, options)
        add_internal_attribute property, options, "_facet", true
        @index.model.sphinx_facets << property.to_facet
      end
      
      def add_internal_attribute(property, options, suffix, crc = false)
        return unless ThinkingSphinx::Facet.translate?(property)
        
        Attribute.new(source,
          property.columns.collect { |col| col.clone },
          options.merge(
            :type => property.is_a?(Field) ? :string : options[:type],
            :as   => property.unique_name.to_s.concat(suffix).to_sym,
            :crc  => crc
          ).except(:facet)
        )
      end
      
      def no_fields?
        @index.sources.empty? || @index.sources.any? { |source|
          source.fields.length == 0
        }
      end
    end
  end
end
