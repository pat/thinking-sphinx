module ThinkingSphinx
  module SearchMethods
    def self.included(base)
      base.class_eval do
        extend ThinkingSphinx::SearchMethods::ClassMethods
      end
    end
    
    module ClassMethods
      def search_context
        # Comparing to name string to avoid class inheritance complications
        case self.class.name
        when 'Class'
          self
        else
          nil
        end
      end
      
      # Searches through the Sphinx indexes for relevant matches. There's
      # various ways to search, sort, group and filter - which are covered
      # below.
      #
      # Also, if you have WillPaginate installed, the search method can be used
      # just like paginate. The same parameters - :page and :per_page - work as
      # expected, and the returned result set can be used by the will_paginate
      # helper.
      # 
      # == Basic Searching
      #
      # The simplest way of searching is straight text.
      # 
      #   ThinkingSphinx.search "pat"
      #   ThinkingSphinx.search "google"
      #   User.search "pat", :page => (params[:page] || 1)
      #   Article.search "relevant news issue of the day"
      #
      # If you specify :include, like in an #find call, this will be respected
      # when loading the relevant models from the search results.
      # 
      #   User.search "pat", :include => :posts
      #
      # == Match Modes
      #
      # Sphinx supports 5 different matching modes. By default Thinking Sphinx
      # uses :all, which unsurprisingly requires all the supplied search terms
      # to match a result.
      #
      # Alternative modes include:
      #
      #   User.search "pat allan", :match_mode => :any
      #   User.search "pat allan", :match_mode => :phrase
      #   User.search "pat | allan", :match_mode => :boolean
      #   User.search "@name pat | @username pat", :match_mode => :extended
      #
      # Any will find results with any of the search terms. Phrase treats the
      # search terms a single phrase instead of individual words. Boolean and 
      # extended allow for more complex query syntax, refer to the sphinx
      # documentation for further details.
      #
      # == Weighting
      #
      # Sphinx has support for weighting, where matches in one field can be
      # considered more important than in another. Weights are integers, with 1
      # as the default. They can be set per-search like this:
      #
      #   User.search "pat allan", :field_weights => { :alias => 4, :aka => 2 }
      #
      # If you're searching multiple models, you can set per-index weights:
      #
      #   ThinkingSphinx.search "pat", :index_weights => { User => 10 }
      #
      # See http://sphinxsearch.com/doc.html#weighting for further details.
      #
      # == Searching by Fields
      # 
      # If you want to step it up a level, you can limit your search terms to
      # specific fields:
      # 
      #   User.search :conditions => {:name => "pat"}
      #
      # This uses Sphinx's extended match mode, unless you specify a different
      # match mode explicitly (but then this way of searching won't work). Also
      # note that you don't need to put in a search string.
      #
      # == Searching by Attributes
      #
      # Also known as filters, you can limit your searches to documents that
      # have specific values for their attributes. There are three ways to do
      # this. The first two techniques work in all scenarios - using the :with
      # or :with_all options.
      #
      #   ThinkingSphinx.search :with => {:tag_ids => 10}
      #   ThinkingSphinx.search :with => {:tag_ids => [10,12]}
      #   ThinkingSphinx.search :with_all => {:tag_ids => [10,12]}
      #
      # The first :with search will match records with a tag_id attribute of 10.
      # The second :with will match records with a tag_id attribute of 10 OR 12.
      # If you need to find records that are tagged with ids 10 AND 12, you
      # will need to use the :with_all search parameter. This is particuarly
      # useful in conjunction with Multi Value Attributes (MVAs).
      #
      # The third filtering technique is only viable if you're searching with a
      # specific model (not multi-model searching). With a single model,
      # Thinking Sphinx can figure out what attributes and fields are available,
      # so you can put it all in the :conditions hash, and it will sort it out.
      # 
      #   Node.search :conditions => {:parent_id => 10}
      # 
      # Filters can be single values, arrays of values, or ranges.
      # 
      #   Article.search "East Timor", :conditions => {:rating => 3..5}
      #
      # == Excluding by Attributes
      #
      # Sphinx also supports negative filtering - where the filters are of
      # attribute values to exclude. This is done with the :without option:
      #
      #   User.search :without => {:role_id => 1}
      #
      # == Excluding by Primary Key
      #
      # There is a shortcut to exclude records by their ActiveRecord primary
      # key:
      #
      #   User.search :without_ids => 1
      #
      # Pass an array or a single value.
      #
      # The primary key must be an integer as a negative filter is used. Note
      # that for multi-model search, an id may occur in more than one model.
      #
      # == Infix (Star) Searching
      # 
      # Enable infix searching by something like this in config/sphinx.yml:
      #
      #   development:
      #     enable_star: 1
      #     min_infix_len: 2
      #
      # Note that this will make indexing take longer.
      #
      # With those settings (and after reindexing), wildcard asterisks can be
      # used in queries:
      #
      #   Location.search "*elbourn*"
      #
      # To automatically add asterisks around every token (but not operators),
      # pass the :star option:
      #
      #   Location.search "elbourn -ustrali", :star => true,
      #     :match_mode => :boolean
      #
      # This would become "*elbourn* -*ustrali*". The :star option only adds the
      # asterisks. You need to make the config/sphinx.yml changes yourself.
      #
      # By default, the tokens are assumed to match the regular expression
      # /\w\+/u\+. If you've modified the charset_table, pass another regular
      # expression, e.g.
      #
      #   User.search("oo@bar.c", :star => /[\w@.]+/u)
      #
      # to search for "*oo@bar.c*" and not "*oo*@*bar*.*c*".
      #
      # == Sorting
      #
      # Sphinx can only sort by attributes, so generally you will need to avoid
      # using field names in your :order option. However, if you're searching
      # on a single model, and have specified some fields as sortable, you can
      # use those field names and Thinking Sphinx will interpret accordingly.
      # Remember: this will only happen for single-model searches, and only
      # through the :order option.
      #
      #   Location.search "Melbourne", :order => :state
      #   User.search :conditions => {:role_id => 2}, :order => "name ASC"
      #
      # Keep in mind that if you use a string, you *must* specify the direction
      # (ASC or DESC) else Sphinx won't return any results. If you use a symbol
      # then Thinking Sphinx assumes ASC, but if you wish to state otherwise,
      # use the :sort_mode option:
      #
      #   Location.search "Melbourne", :order => :state, :sort_mode => :desc
      #
      # Of course, there are other sort modes - check out the Sphinx
      # documentation[http://sphinxsearch.com/doc.html] for that level of
      # detail though.
      #
      # If desired, you can sort by a column in your model instead of a sphinx
      # field or attribute. This sort only applies to the current page, so is
      # most useful when performing a search with a single page of results.
      #
      #   User.search("pat", :sql_order => "name")
      #
      # == Grouping
      # 
      # For this you can use the group_by, group_clause and group_function
      # options - which are all directly linked to Sphinx's expectations. No
      # magic from Thinking Sphinx. It can get a little tricky, so make sure
      # you read all the relevant
      # documentation[http://sphinxsearch.com/doc.html#clustering] first.
      # 
      # Grouping is done via three parameters within the options hash
      # * <tt>:group_function</tt> determines the way grouping is done
      # * <tt>:group_by</tt> determines the field which is used for grouping
      # * <tt>:group_clause</tt> determines the sorting order 
      #
      # As a convenience, you can also use
      # * <tt>:group</tt>
      # which sets :group_by and defaults to :group_function of :attr
      # 
      # === group_function
      #  
      # Valid values for :group_function are
      # * <tt>:day</tt>, <tt>:week</tt>, <tt>:month</tt>, <tt>:year</tt> - Grouping is done by the respective timeframes. 
      # * <tt>:attr</tt>, <tt>:attrpair</tt> - Grouping is done by the specified attributes(s)
      # 
      # === group_by
      #
      # This parameter denotes the field by which grouping is done. Note that
      # the specified field must be a sphinx attribute or index.
      #
      # === group_clause
      #
      # This determines the sorting order of the groups. In a grouping search,
      # the matches within a group will sorted by the <tt>:sort_mode</tt> and
      # <tt>:order</tt> parameters. The group matches themselves however, will
      # be sorted by <tt>:group_clause</tt>. 
      # 
      # The syntax for this is the same as an order parameter in extended sort
      # mode. Namely, you can specify an SQL-like sort expression with up to 5
      # attributes (including internal attributes), eg: "@relevance DESC, price
      # ASC, @id DESC"
      #
      # === Grouping by timestamp
      # 
      # Timestamp grouping groups off items by the day, week, month or year of 
      # the attribute given. In order to do this you need to define a timestamp
      # attribute, which pretty much looks like the standard defintion for any
      # attribute.
      #
      #   define_index do
      #     #
      #     # All your other stuff
      #     #
      #     has :created_at
      #   end
      #
      # When you need to fire off your search, it'll go something to the tune of
      #   
      #   Fruit.search "apricot", :group_function => :day,
      #     :group_by => 'created_at'
      #
      # The <tt>@groupby</tt> special attribute will contain the date for that
      # group. Depending on the <tt>:group_function</tt> parameter, the date
      # format will be:
      #
      # * <tt>:day</tt> - YYYYMMDD
      # * <tt>:week</tt> - YYYYNNN (NNN is the first day of the week in question, 
      #   counting from the start of the year )
      # * <tt>:month</tt> - YYYYMM
      # * <tt>:year</tt> - YYYY
      #
      # === Grouping by attribute
      #
      # The syntax is the same as grouping by timestamp, except for the fact
      # that the <tt>:group_function</tt> parameter is changed.
      #
      #   Fruit.search "apricot", :group_function => :attr, :group_by => 'size'
      # 
      # == Geo/Location Searching
      #
      # Sphinx - and therefore Thinking Sphinx - has the facility to search
      # around a geographical point, using a given latitude and longitude. To
      # take advantage of this, you will need to have both of those values in
      # attributes. To search with that point, you can then use one of the
      # following syntax examples:
      # 
      #   Address.search "Melbourne", :geo => [1.4, -2.217],
      #     :order => "@geodist asc"
      #   Address.search "Australia", :geo => [-0.55, 3.108],
      #     :order => "@geodist asc" :latitude_attr => "latit",
      #     :longitude_attr => "longit"
      # 
      # The first example applies when your latitude and longitude attributes
      # are named any of lat, latitude, lon, long or longitude. If that's not
      # the case, you will need to explicitly state them in your search, _or_
      # you can do so in your model:
      #
      #   define_index do
      #     has :latit  # Float column, stored in radians
      #     has :longit # Float column, stored in radians
      #     
      #     set_property :latitude_attr   => "latit"
      #     set_property :longitude_attr  => "longit"
      #   end
      # 
      # Now, geo-location searching really only has an affect if you have a
      # filter, sort or grouping clause related to it - otherwise it's just a
      # normal search, and _will not_ return a distance value otherwise. To
      # make use of the positioning difference, use the special attribute
      # "@geodist" in any of your filters or sorting or grouping clauses.
      # 
      # And don't forget - both the latitude and longitude you use in your
      # search, and the values in your indexes, need to be stored as a float in
      # radians, _not_ degrees. Keep in mind that if you do this conversion in 
      # SQL you will need to explicitly declare a column type of :float.
      #
      #   define_index do
      #     has 'RADIANS(lat)', :as => :lat,  :type => :float
      #     # ...
      #   end
      # 
      # Once you've got your results set, you can access the distances as
      # follows:
      # 
      #   @results.each_with_geodist do |result, distance|
      #     # ...
      #   end
      # 
      # The distance value is returned as a float, representing the distance in
      # metres.
      # 
      # == Filtering by custom attributes
      #
      # Do note that this applies only to sphinx 0.9.9
      # 
      # Should you find yourself in desperate need of a filter that involves
      # selecting either one of multiple conditions, one solution could be
      # provided by the :sphinx_select option within the search. 
      # This handles which fields are selected by sphinx from its store.
      #
      # The default value is "*", and you can add custom fields using syntax
      # similar to sql:
      #
      #   Flower.search "foo",
      #     :sphinx_select => "*, petals < 1 or color = 2 as grass"
      #
      # This will add the 'grass' attribute, which will now be usable in your
      # filters.
      #   
      # == Handling a Stale Index
      #
      # Especially if you don't use delta indexing, you risk having records in
      # the Sphinx index that are no longer in the database. By default, those 
      # will simply come back as nils:
      #
      #   >> pat_user.delete
      #   >> User.search("pat")
      #   Sphinx Result: [1,2]
      #   => [nil, <#User id: 2>]
      #
      # (If you search across multiple models, you'll get
      # ActiveRecord::RecordNotFound.)
      #
      # You can simply Array#compact these results or handle the nils in some 
      # other way, but Sphinx will still report two results, and the missing
      # records may upset your layout.
      #
      # If you pass :retry_stale => true to a single-model search, missing
      # records will cause Thinking Sphinx to retry the query but excluding
      # those records. Since search is paginated, the new search could
      # potentially include missing records as well, so by default Thinking
      # Sphinx will retry three times. Pass :retry_stale => 5 to retry five
      # times, and so on. If there are still missing ids on the last retry, they
      # are shown as nils.
      # 
      def search(*args)
        ThinkingSphinx::Search.new *search_options(args)
      end
      
      # Searches for results that match the parameters provided. Will only
      # return the ids for the matching objects. See #search for syntax
      # examples.
      #
      # Note that this only searches the Sphinx index, with no ActiveRecord
      # queries. Thus, if your index is not in sync with the database, this
      # method may return ids that no longer exist there.
      #
      def search_for_ids(*args)
        ThinkingSphinx::Search.new *search_options(args, :ids_only => true)
      end
      
      # Checks if a document with the given id exists within a specific index.
      # Expected parameters:
      #
      # - ID of the document
      # - Index to check within
      # - Options hash (defaults to {})
      # 
      # Example:
      # 
      #   ThinkingSphinx.search_for_id(10, "user_core", :class => User)
      # 
      def search_for_id(id, index, options = {})
        ThinkingSphinx::Search.new(
          *search_options([],
            :ids_only => true,
            :index    => index,
            :id_range => id..id
          )
        ).any?
      end
      
      def count(*args)
        search_context ? super : search_count(*args)
      end
      
      def search_count(*args)
        search = ThinkingSphinx::Search.new(
          *search_options(args, :ids_only => true)
        )
        search.first # forces the query
        search.total_entries
      end
      
      # Model.facets *args
      # ThinkingSphinx.facets *args
      # ThinkingSphinx.facets *args, :all_facets  => true
      # ThinkingSphinx.facets *args, :class_facet     => false
      # 
      def facets(*args)
        ThinkingSphinx::FacetSearch.new *search_options(args)
      end
      
      private
      
      def search_options(args, options = {})
        options = args.extract_options!.merge(options)
        options[:classes] ||= classes_option
        args << options
      end
      
      def classes_option
        classes_option = [search_context].compact
        classes_option.empty? ? nil : classes_option
      end
    end
  end
end
