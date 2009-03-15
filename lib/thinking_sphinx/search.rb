module ThinkingSphinx
  # Once you've got those indexes in and built, this is the stuff that
  # matters - how to search! This class provides a generic search
  # interface - which you can use to search all your indexed models at once.
  # Most times, you will just want a specific model's results - to search and
  # search_for_ids methods will do the job in exactly the same manner when
  # called from a model.
  # 
  class Search
    GlobalFacetOptions = {
      :all_attributes => false,
      :class_facet    => true
    }
    
    class << self
      # Searches for results that match the parameters provided. Will only
      # return the ids for the matching objects. See #search for syntax
      # examples.
      #
      # Note that this only searches the Sphinx index, with no ActiveRecord
      # queries. Thus, if your index is not in sync with the database, this
      # method may return ids that no longer exist there.
      #
      def search_for_ids(*args)
        results, client = search_results(*args.clone)
        
        options = args.extract_options!
        page    = options[:page] ? options[:page].to_i : 1
        
        ThinkingSphinx::Collection.ids_from_results(results, page, client.limit, options)
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
      #   ThinkingSphinx::Search.search "pat"
      #   ThinkingSphinx::Search.search "google"
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
      # Any will find results with any of the search terms. Phrase treats the search
      # terms a single phrase instead of individual words. Boolean and extended allow
      # for more complex query syntax, refer to the sphinx documentation for further
      # details.
      #
      # == Weighting
      #
      # Sphinx has support for weighting, where matches in one field can be considered
      # more important than in another. Weights are integers, with 1 as the default.
      # They can be set per-search like this:
      #
      #   User.search "pat allan", :field_weights => { :alias => 4, :aka => 2 }
      #
      # If you're searching multiple models, you can set per-index weights:
      #
      #   ThinkingSphinx::Search.search "pat", :index_weights => { User => 10 }
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
      #   ThinkingSphinx::Search.search :with => {:tag_ids => 10}
      #   ThinkingSphinx::Search.search :with => {:tag_ids => [10,12]}
      #   ThinkingSphinx::Search.search :with_all => {:tag_ids => [10,12]}
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
      # There is a shortcut to exclude records by their ActiveRecord primary key:
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
      # By default, Sphinx uses English stemming, e.g. matching "shoes" if you
      # search for "shoe". It won't find "Melbourne" if you search for
      # "elbourn", though.
      #
      # Enable infix searching by something like this in config/sphinx.yml:
      #
      #   development:
      #     enable_star: 1
      #     min_infix_length: 2
      #
      # Note that this will make indexing take longer.
      #
      # With those settings (and after reindexing), wildcard asterisks can be used
      # in queries:
      #
      #   Location.search "*elbourn*"
      #
      # To automatically add asterisks around every token (but not operators),
      # pass the :star option:
      #
      #   Location.search "elbourn -ustrali", :star => true, :match_mode => :boolean
      #
      # This would become "*elbourn* -*ustrali*". The :star option only adds the
      # asterisks. You need to make the config/sphinx.yml changes yourself.
      #
      # By default, the tokens are assumed to match the regular expression /\w+/u.
      # If you've modified the charset_table, pass another regular expression, e.g.
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
      # Yes this section will be expanded, but this is a start.
      #
      # == Geo/Location Searching
      #
      # Sphinx - and therefore Thinking Sphinx - has the facility to search
      # around a geographical point, using a given latitude and longitude. To
      # take advantage of this, you will need to have both of those values in
      # attributes. To search with that point, you can then use one of the
      # following syntax examples:
      # 
      #   Address.search "Melbourne", :geo => [1.4, -2.217], :order => "@geodist asc"
      #   Address.search "Australia", :geo => [-0.55, 3.108], :order => "@geodist asc"
      #     :latitude_attr => "latit", :longitude_attr => "longit"
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
      # search, and the values in your indexes, need to be stored as a float in radians,
      # _not_ degrees. Keep in mind that if you do this conversion in SQL
      # you will need to explicitly declare a column type of :float.
      #
      #   define_index do
      #     has 'RADIANS(lat)', :as => :lat,  :type => :float
      #     # ...
      #   end
      # 
      # Once you've got your results set, you can access the distances as
      # follows:
      # 
      # @results.each_with_geodist do |result, distance|
      #   # ...
      # end
      # 
      # The distance value is returned as a float, representing the distance in
      # metres.
      # 
      # == Handling a Stale Index
      #
      # Especially if you don't use delta indexing, you risk having records in the
      # Sphinx index that are no longer in the database. By default, those will simply
      # come back as nils:
      #
      #   >> pat_user.delete
      #   >> User.search("pat")
      #   Sphinx Result: [1,2]
      #   => [nil, <#User id: 2>]
      #
      # (If you search across multiple models, you'll get ActiveRecord::RecordNotFound.)
      #
      # You can simply Array#compact these results or handle the nils in some other way, but
      # Sphinx will still report two results, and the missing records may upset your layout.
      #
      # If you pass :retry_stale => true to a single-model search, missing records will
      # cause Thinking Sphinx to retry the query but excluding those records. Since search
      # is paginated, the new search could potentially include missing records as well, so by
      # default Thinking Sphinx will retry three times. Pass :retry_stale => 5 to retry five
      # times, and so on. If there are still missing ids on the last retry, they are
      # shown as nils.
      # 
      def search(*args)
        query = args.clone  # an array
        options = query.extract_options!
        
        retry_search_on_stale_index(query, options) do
          results, client = search_results(*(query + [options]))
        
          ::ActiveRecord::Base.logger.error(
            "Sphinx Error: #{results[:error]}"
          ) if results[:error]
        
          klass   = options[:class]
          page    = options[:page] ? options[:page].to_i : 1
        
          ThinkingSphinx::Collection.create_from_results(results, page, client.limit, options)
        end
      end
      
      def retry_search_on_stale_index(query, options, &block)
        stale_ids = []
        stale_retries_left = case options[:retry_stale]
                              when true
                                3  # default to three retries
                              when nil, false
                                0  # no retries
                              else             options[:retry_stale].to_i
                              end
        begin
          # Passing this in an option so Collection.create_from_results can see it.
          # It should only raise on stale records if there are any retries left.
          options[:raise_on_stale] = stale_retries_left > 0
          block.call
        # If ThinkingSphinx::Collection.create_from_results found records in Sphinx but not
        # in the DB and the :raise_on_stale option is set, this exception is raised. We retry
        # a limited number of times, excluding the stale ids from the search.
        rescue StaleIdsException => e
          stale_retries_left -= 1

          stale_ids |= e.ids  # For logging
          options[:without_ids] = Array(options[:without_ids]) | e.ids  # Actual exclusion

          tries = stale_retries_left
          ::ActiveRecord::Base.logger.debug("Sphinx Stale Ids (%s %s left): %s" % [
              tries, (tries==1 ? 'try' : 'tries'), stale_ids.join(', ')
          ])
          
          retry
        end
      end

      def count(*args)
        results, client = search_results(*args.clone)
        results[:total_found] || 0
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
      #   ThinkingSphinx::Search.search_for_id(10, "user_core", :class => User)
      # 
      def search_for_id(*args)
        options = args.extract_options!
        client  = client_from_options options
        
        query, filters    = search_conditions(
          options[:class], options[:conditions] || {}
        )
        client.filters   += filters
        client.match_mode = :extended unless query.empty?
        client.id_range   = args.first..args.first
        
        begin
          return client.query(query, args[1])[:matches].length > 0
        rescue Errno::ECONNREFUSED => err
          raise ThinkingSphinx::ConnectionError, "Connection to Sphinx Daemon (searchd) failed."
        end
      end
      
      # Model.facets *args
      # ThinkingSphinx::Search.facets *args
      # ThinkingSphinx::Search.facets *args, :all_attributes  => true
      # ThinkingSphinx::Search.facets *args, :class_facet     => false
      # 
      def facets(*args)
        options = args.extract_options!
        
        if options[:class]
          facets_for_model options[:class], args, options
        else
          facets_for_all_models args, options
        end
      end
      
      private
      
      # This method handles the common search functionality, and returns both
      # the result hash and the client. Not super elegant, but it'll do for
      # the moment.
      # 
      def search_results(*args)
        options = args.extract_options!
        query   = args.join(' ')
        client  = client_from_options options
        
        query = star_query(query, options[:star]) if options[:star]
        
        extra_query, filters = search_conditions(
          options[:class], options[:conditions] || {}
        )
        client.filters   += filters
        client.match_mode = :extended unless extra_query.empty?
        query             = [query, extra_query].join(' ')
        query.strip!  # Because "" and " " are not equivalent
                
        set_sort_options! client, options
        
        client.limit  = options[:per_page].to_i if options[:per_page]
        page          = options[:page] ? options[:page].to_i : 1
        page          = 1 if page <= 0
        client.offset = (page - 1) * client.limit

        begin
          ::ActiveRecord::Base.logger.debug "Sphinx: #{query}"
          results = client.query query
          ::ActiveRecord::Base.logger.debug "Sphinx Result: #{results[:matches].collect{|m| m[:attributes]["sphinx_internal_id"]}.inspect}"
        rescue Errno::ECONNREFUSED => err
          raise ThinkingSphinx::ConnectionError, "Connection to Sphinx Daemon (searchd) failed."
        end
        
        return results, client
      end
      
      # Set all the appropriate settings for the client, using the provided
      # options hash.
      # 
      def client_from_options(options = {})
        config = ThinkingSphinx::Configuration.instance
        client = Riddle::Client.new config.address, config.port
        klass  = options[:class]
        index_options = klass ? klass.sphinx_index_options : {}

        # The Riddle default is per-query max_matches=1000. If we set the
        # per-server max to a smaller value in sphinx.yml, we need to override
        # the Riddle default or else we get search errors like
        # "per-query max_matches=1000 out of bounds (per-server max_matches=200)"
        if per_server_max_matches = config.configuration.searchd.max_matches
          options[:max_matches] ||= per_server_max_matches
        end
        
        # Turn :index_weights => { "foo" => 2, User => 1 }
        # into :index_weights => { "foo" => 2, "user_core" => 1, "user_delta" => 1 }
        if iw = options[:index_weights]
          options[:index_weights] = iw.inject({}) do |hash, (index,weight)|
            if index.is_a?(Class)
              name = ThinkingSphinx::Index.name(index)
              hash["#{name}_core"]  = weight
              hash["#{name}_delta"] = weight
            else
              hash[index] = weight
            end
            hash
          end
        end
        
        [
          :max_matches, :match_mode, :sort_mode, :sort_by, :id_range,
          :group_by, :group_function, :group_clause, :group_distinct, :cut_off,
          :retry_count, :retry_delay, :index_weights, :rank_mode,
          :max_query_time, :field_weights, :filters, :anchor, :limit
        ].each do |key|
          client.send(
            key.to_s.concat("=").to_sym,
            options[key] || index_options[key] || client.send(key)
          )
        end
        
        options[:classes] = [klass] if klass
        
        client.anchor = anchor_conditions(klass, options) || {} if client.anchor.empty?
        
        client.filters << Riddle::Client::Filter.new(
          "sphinx_deleted", [0]
        )
        
        # class filters
        client.filters << Riddle::Client::Filter.new(
          "class_crc", options[:classes].collect { |k| k.to_crc32s }.flatten
        ) if options[:classes]
        
        # normal attribute filters
        client.filters += options[:with].collect { |attr,val|
          Riddle::Client::Filter.new attr.to_s, filter_value(val)
        } if options[:with]
        
        # exclusive attribute filters
        client.filters += options[:without].collect { |attr,val|
          Riddle::Client::Filter.new attr.to_s, filter_value(val), true
        } if options[:without]
        
        # every-match attribute filters
        client.filters += options[:with_all].collect { |attr,vals|
          Array(vals).collect { |val|
            Riddle::Client::Filter.new attr.to_s, filter_value(val)
          }
        }.flatten if options[:with_all]
        
        # exclusive attribute filter on primary key
        client.filters += Array(options[:without_ids]).collect { |id|
          Riddle::Client::Filter.new 'sphinx_internal_id', filter_value(id), true
        } if options[:without_ids]
        
        client
      end
      
      def star_query(query, custom_token = nil)
        token = custom_token.is_a?(Regexp) ? custom_token : /\w+/u

        query.gsub(/("#{token}(.*?#{token})?"|(?![!-])#{token})/u) do
          pre, proper, post = $`, $&, $'
          is_operator = pre.match(%r{(\W|^)[@~/]\Z})  # E.g. "@foo", "/2", "~3", but not as part of a token
          is_quote    = proper.starts_with?('"') && proper.ends_with?('"')  # E.g. "foo bar", with quotes
          has_star    = pre.ends_with?("*") || post.starts_with?("*")
          if is_operator || is_quote || has_star
            proper
          else
            "*#{proper}*"
          end
        end
      end
      
      def filter_value(value)
        case value
        when Range
          value.first.is_a?(Time) ? timestamp(value.first)..timestamp(value.last) : value
        when Array
          value.collect { |val| val.is_a?(Time) ? timestamp(val) : val }
        else
          Array(value)
        end
      end
      
      # Returns the integer timestamp for a Time object.
      # 
      # If using Rails 2.1+, need to handle timezones to translate them back to
      # UTC, as that's what datetimes will be stored as by MySQL.
      # 
      # in_time_zone is a method that was added for the timezone support in
      # Rails 2.1, which is why it's used for testing. I'm sure there's better
      # ways, but this does the job.
      # 
      def timestamp(value)
        value.respond_to?(:in_time_zone) ? value.utc.to_i : value.to_i
      end
      
      # Translate field and attribute conditions to the relevant search string
      # and filters.
      # 
      def search_conditions(klass, conditions={})
        attributes = klass ? klass.sphinx_indexes.collect { |index|
          index.attributes.collect { |attrib| attrib.unique_name }
        }.flatten : []
        
        search_string = []
        filters       = []
        
        conditions.each do |key,val|
          if attributes.include?(key.to_sym)
            filters << Riddle::Client::Filter.new(
              key.to_s, filter_value(val)
            )
          else
            search_string << "@#{key} #{val}"
          end
        end
        
        return search_string.join(' '), filters
      end
      
      # Return the appropriate latitude and longitude values, depending on
      # whether the relevant attributes have been defined, and also whether
      # there's actually any values.
      # 
      def anchor_conditions(klass, options)
        attributes = klass ? klass.sphinx_indexes.collect { |index|
          index.attributes.collect { |attrib| attrib.unique_name }
        }.flatten : []
        
        lat_attr = klass ? klass.sphinx_indexes.collect { |index|
          index.options[:latitude_attr]
        }.compact.first : nil
        
        lon_attr = klass ? klass.sphinx_indexes.collect { |index|
          index.options[:longitude_attr]
        }.compact.first : nil
        
        lat_attr = options[:latitude_attr] if options[:latitude_attr]
        lat_attr ||= :lat       if attributes.include?(:lat)
        lat_attr ||= :latitude  if attributes.include?(:latitude)
        
        lon_attr = options[:longitude_attr] if options[:longitude_attr]
        lon_attr ||= :lng       if attributes.include?(:lng)
        lon_attr ||= :lon       if attributes.include?(:lon)
        lon_attr ||= :long      if attributes.include?(:long)
        lon_attr ||= :longitude if attributes.include?(:longitude)
        
        lat = options[:lat]
        lon = options[:lon]
        
        if options[:geo]
          lat = options[:geo].first
          lon = options[:geo].last
        end
        
        lat && lon ? {
          :latitude_attribute   => lat_attr.to_s,
          :latitude             => lat,
          :longitude_attribute  => lon_attr.to_s,
          :longitude            => lon
        } : nil
      end
      
      # Set the sort options using the :order key as well as the appropriate
      # Riddle settings.
      # 
      def set_sort_options!(client, options)
        klass = options[:class]
        fields = klass ? klass.sphinx_indexes.collect { |index|
          index.fields.collect { |field| field.unique_name }
        }.flatten : []
        index_options = klass ? klass.sphinx_index_options : {}

        order = options[:order] || index_options[:order]        
        case order
        when Symbol
          client.sort_mode = :attr_asc if client.sort_mode == :relevance || client.sort_mode.nil?
          if fields.include?(order)
            client.sort_by = order.to_s.concat("_sort")
          else
            client.sort_by = order.to_s
          end
        when String
          client.sort_mode = :extended
          client.sort_by   = sorted_fields_to_attributes(order, fields)
        else
          # do nothing
        end
        
        client.sort_mode = :attr_asc  if client.sort_mode == :asc
        client.sort_mode = :attr_desc if client.sort_mode == :desc
      end
      
      # Search through a collection of fields and translate any appearances
      # of them in a string to their attribute equivalent for sorting.
      # 
      def sorted_fields_to_attributes(string, fields)
        fields.each { |field|
          string.gsub!(/(^|\s)#{field}(,?\s|$)/) { |match|
            match.gsub field.to_s, field.to_s.concat("_sort")
          }
        }
        
        string
      end
      
      def facets_for_model(klass, args, options)
        hash    = ThinkingSphinx::FacetCollection.new args + [options]
        options = options.clone.merge! :group_function => :attr
        
        klass.sphinx_facets.inject(hash) do |hash, facet|
          unless facet.name == :class && !options[:class_facet]
            options[:group_by] = facet.attribute_name
            hash.add_from_results facet, search(*(args + [options]))
          end
          
          hash
        end
      end
      
      def facets_for_all_models(args, options)
        options = GlobalFacetOptions.merge(options)
        hash    = ThinkingSphinx::FacetCollection.new args + [options]
        options = options.merge! :group_function => :attr
        
        facet_names(options).inject(hash) do |hash, name|
          options[:group_by] = name
          hash.add_from_results name, search(*(args + [options]))
          hash
        end
      end
      
      def facet_classes(options)
        options[:classes] || ThinkingSphinx.indexed_models.collect { |model|
          model.constantize
        }
      end
      
      def facet_names(options)
        classes = facet_classes(options)
        names   = options[:all_attributes] ?
          facet_names_for_all_classes(classes) :
          facet_names_common_to_all_classes(classes)
        
        names.delete "class_crc" unless options[:class_facet]
        names
      end
      
      def facet_names_for_all_classes(classes)
        classes.collect { |klass|
          klass.sphinx_facets.collect { |facet| facet.attribute_name }
        }.flatten.uniq
      end
      
      def facet_names_common_to_all_classes(classes)
        facet_names_for_all_classes(classes).select { |name|
          classes.all? { |klass|
            klass.sphinx_facets.detect { |facet|
              facet.attribute_name == name
            }
          }
        }
      end
    end
  end
end
