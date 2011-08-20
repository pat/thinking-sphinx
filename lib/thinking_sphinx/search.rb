# encoding: UTF-8
module ThinkingSphinx
  # Once you've got those indexes in and built, this is the stuff that
  # matters - how to search! This class provides a generic search
  # interface - which you can use to search all your indexed models at once.
  # Most times, you will just want a specific model's results - to search and
  # search_for_ids methods will do the job in exactly the same manner when
  # called from a model.
  #
  class Search < Array
    CoreMethods = %w( == class class_eval extend frozen? id instance_eval
      instance_of? instance_values instance_variable_defined?
      instance_variable_get instance_variable_set instance_variables is_a?
      kind_of? member? method methods nil? object_id respond_to?
      respond_to_missing? send should type )
    SafeMethods = %w( partition private_methods protected_methods
      public_methods send class )

    instance_methods.select { |method|
      method.to_s[/^__/].nil? && !CoreMethods.include?(method.to_s)
    }.each { |method|
      undef_method method
    }

    HashOptions   = [:conditions, :with, :without, :with_all, :without_any]
    ArrayOptions  = [:classes, :without_ids]

    attr_reader :args, :options

    # Deprecated. Use ThinkingSphinx.search
    def self.search(*args)
      warn 'ThinkingSphinx::Search.search is deprecated. Please use ThinkingSphinx.search instead.'
      ThinkingSphinx.search(*args)
    end

    # Deprecated. Use ThinkingSphinx.search_for_ids
    def self.search_for_ids(*args)
      warn 'ThinkingSphinx::Search.search_for_ids is deprecated. Please use ThinkingSphinx.search_for_ids instead.'
      ThinkingSphinx.search_for_ids(*args)
    end

    # Deprecated. Use ThinkingSphinx.search_for_ids
    def self.search_for_id(*args)
      warn 'ThinkingSphinx::Search.search_for_id is deprecated. Please use ThinkingSphinx.search_for_id instead.'
      ThinkingSphinx.search_for_id(*args)
    end

    # Deprecated. Use ThinkingSphinx.count
    def self.count(*args)
      warn 'ThinkingSphinx::Search.count is deprecated. Please use ThinkingSphinx.count instead.'
      ThinkingSphinx.count(*args)
    end

    # Deprecated. Use ThinkingSphinx.facets
    def self.facets(*args)
      warn 'ThinkingSphinx::Search.facets is deprecated. Please use ThinkingSphinx.facets instead.'
      ThinkingSphinx.facets(*args)
    end

    def self.bundle_searches(enum = nil)
      bundle = ThinkingSphinx::BundledSearch.new

      if enum.nil?
        yield bundle
      else
        enum.each { |item| yield bundle, item }
      end

      bundle.searches
    end

    def self.matching_fields(fields, bitmask)
      matches   = []
      bitstring = bitmask.to_s(2).rjust(32, '0').reverse

      fields.each_with_index do |field, index|
        matches << field if bitstring[index, 1] == '1'
      end
      matches
    end

    def initialize(*args)
      ThinkingSphinx.context.define_indexes

      @array    = []
      @options  = args.extract_options!
      @args     = args

      add_default_scope unless options[:ignore_default]

      populate if @options[:populate]
    end

    def to_a
      populate
      @array
    end

    def freeze
      populate
      @array.freeze
      self
    end

    # Indication of whether the request has been made to Sphinx for the search
    # query.
    #
    # @return [Boolean] true if the results have been requested.
    #
    def populated?
      !!@populated
    end

    # Indication of whether the request resulted in an error from Sphinx.
    #
    # @return [Boolean] true if Sphinx reports query error
    #
    def error?
      !!error
    end

    # The Sphinx-reported error, if any.
    #
    # @return [String, nil]
    #
    def error
      populate
      @results[:error]
    end

    # Indication of whether the request resulted in a warning from Sphinx.
    #
    # @return [Boolean] true if Sphinx reports query warning
    #
    def warning?
      !!warning
    end

    # The Sphinx-reported warning, if any.
    #
    # @return [String, nil]
    #
    def warning
      populate
      @results[:warning]
    end

    # The query result hash from Riddle.
    #
    # @return [Hash] Raw Sphinx results
    #
    def results
      populate
      @results
    end

    def method_missing(method, *args, &block)
      if is_scope?(method)
        add_scope(method, *args, &block)
        return self
      elsif method == :search_count
        merge_search one_class.search(*args), self.args, options
        return scoped_count
      elsif method.to_s[/^each_with_.*/].nil? && !@array.respond_to?(method)
        super
      elsif !SafeMethods.include?(method.to_s)
        populate
      end

      if method.to_s[/^each_with_.*/] && !@array.respond_to?(method)
        each_with_attribute method.to_s.gsub(/^each_with_/, ''), &block
      else
        @array.send(method, *args, &block)
      end
    end

    # Returns true if the Search object or the underlying Array object respond
    # to the requested method.
    #
    # @param [Symbol] method The method name
    # @return [Boolean] true if either Search or Array responds to the method.
    #
    def respond_to?(method, include_private = false)
      super || @array.respond_to?(method, include_private)
    end

    # The current page number of the result set. Defaults to 1 if no page was
    # explicitly requested.
    #
    # @return [Integer]
    #
    def current_page
      @options[:page].blank? ? 1 : @options[:page].to_i
    end

    def first_page?
      current_page == 1
    end

    # Kaminari support
    def page(page_number)
      @options[:page] = page_number
      self
    end

    # The next page number of the result set. If there are no more pages
    # available, nil is returned.
    #
    # @return [Integer, nil]
    #
    def next_page
      current_page >= total_pages ? nil : current_page + 1
    end

    def next_page?
      !next_page.nil?
    end

    # The previous page number of the result set. If this is the first page,
    # then nil is returned.
    #
    # @return [Integer, nil]
    #
    def previous_page
      current_page == 1 ? nil : current_page - 1
    end

    # The amount of records per set of paged results. Defaults to 20 unless a
    # specific page size is requested.
    #
    # @return [Integer]
    #
    def per_page
      @options[:limit] ||= @options[:per_page]
      @options[:limit] ||= 20
      @options[:limit].to_i
    end
    # Kaminari support
    alias_method :limit_value, :per_page

    # Kaminari support
    def per(limit)
      @options[:limit] = limit
      self
    end

    # The total number of pages available if the results are paginated.
    #
    # @return [Integer]
    #
    def total_pages
      populate
      return 0 if @results[:total].nil?

      @total_pages ||= (@results[:total] / per_page.to_f).ceil
    end
    # Compatibility with kaminari and older versions of will_paginate
    alias_method :page_count, :total_pages
    alias_method :num_pages,  :total_pages

    # Query time taken
    #
    # @return [Integer]
    #
    def query_time
      populate
      return 0 if @results[:time].nil?

      @query_time ||= @results[:time]
    end

    # The total number of search results available.
    #
    # @return [Integer]
    #
    def total_entries
      populate
      return 0 if @results[:total_found].nil?

      @total_entries ||= @results[:total_found]
    end

    # Compatibility with kaminari
    alias_method :total_count, :total_entries

    # The current page's offset, based on the number of records per page.
    # Or explicit :offset if given.
    #
    # @return [Integer]
    #
    def offset
      @options[:offset] || ((current_page - 1) * per_page)
    end

    def indexes
      return options[:index] if options[:index]
      return '*' if classes.empty?

      classes.collect { |klass|
        klass.sphinx_index_names
      }.flatten.uniq.join(',')
    end

    def each_with_groupby_and_count(&block)
      populate
      results[:matches].each_with_index do |match, index|
        yield self[index],
          match[:attributes]["@groupby"],
          match[:attributes]["@count"]
      end
    end
    alias_method :each_with_group_and_count, :each_with_groupby_and_count

    def each_with_weighting(&block)
      populate
      results[:matches].each_with_index do |match, index|
        yield self[index], match[:weight]
      end
    end

    def each_with_match(&block)
      populate
      results[:matches].each_with_index do |match, index|
        yield self[index], match
      end
    end

    def excerpt_for(string, model = nil)
      if model.nil? && one_class
        model ||= one_class
      end

      populate

      index = options[:index] || "#{model.core_index_names.first}"
      client.excerpts(
        {
          :docs   => [string.to_s],
          :words  => results[:words].keys.join(' '),
          :index  => index.split(',').first.strip
        }.merge(options[:excerpt_options] || {})
      ).first
    end

    def search(*args)
      args << args.extract_options!.merge(:ignore_default => true)
      merge_search ThinkingSphinx::Search.new(*args), self.args, options
      self
    end

    def search_for_ids(*args)
      args << args.extract_options!.merge(
        :ignore_default => true,
        :ids_only       => true
      )
      merge_search ThinkingSphinx::Search.new(*args), self.args, options
      self
    end

    def facets(*args)
      options = args.extract_options!
      merge_search self, args, options
      args << options

      ThinkingSphinx::FacetSearch.new(*args)
    end

    def client
      client = options[:client] || config.client

      prepare client
    end

    def append_to(client)
      prepare client
      client.append_query query, indexes, comment
      client.reset
    end

    def populate_from_queue(results)
      return if @populated
      @populated = true
      @results   = results

      compose_results
    end

    private

    def config
      ThinkingSphinx::Configuration.instance
    end

    def populate
      return if @populated
      @populated = true

      retry_on_stale_index do
        begin
          log "Querying: '#{query}'"
          runtime = Benchmark.realtime {
            @results = client.query query, indexes, comment
          }
          log "Found #{@results[:total_found]} results", :debug,
            "Sphinx (#{sprintf("%f", runtime)}s)"

          log "Sphinx Daemon returned warning: #{warning}", :error if warning?

          if error?
            log "Sphinx Daemon returned error: #{error}", :error
            raise SphinxError.new(error, @results) unless options[:ignore_errors]
          end
        rescue Errno::ECONNREFUSED => err
          raise ThinkingSphinx::ConnectionError,
            'Connection to Sphinx Daemon (searchd) failed.'
        end

        compose_results
      end
    end

    def compose_results
      if options[:ids_only]
        compose_ids_results
      elsif options[:only]
        compose_only_results
      else
        replace instances_from_matches
        add_excerpter
        add_sphinx_attributes
        add_matching_fields if client.rank_mode == :fieldmask
      end
    end

    def compose_ids_results
      replace @results[:matches].collect { |match|
        match[:attributes]['sphinx_internal_id']
      }
    end

    def compose_only_results
      replace @results[:matches].collect { |match|
        case only = options[:only]
        when String, Symbol
          match[:attributes][only.to_s]
        when Array
          only.inject({}) do |hash, attribute|
            hash[attribute.to_sym] = match[:attributes][attribute.to_s]
            hash
          end
        else
          raise "Unexpected object for :only argument. String or Array is expected, #{only.class} was received."
        end
      }
    end

    def add_excerpter
      each do |object|
        next if object.nil?

        object.excerpts = ThinkingSphinx::Excerpter.new self, object
      end
    end

    def add_sphinx_attributes
      each do |object|
        next if object.nil?

        match = match_hash object
        next if match.nil?

        object.sphinx_attributes = match[:attributes]
      end
    end

    def add_matching_fields
      each do |object|
        next if object.nil?

        match = match_hash object
        next if match.nil?
        object.matching_fields = ThinkingSphinx::Search.matching_fields(
          @results[:fields], match[:weight]
        )
      end
    end

    def match_hash(object)
      @results[:matches].detect { |match|
        class_crc = object.class.name
        class_crc = object.class.to_crc32 if Riddle.loaded_version.to_i < 2

        match[:attributes]['sphinx_internal_id'] == object.
          primary_key_for_sphinx &&
        match[:attributes][crc_attribute] == class_crc
      }
    end

    def self.log(message, method = :debug, identifier = 'Sphinx')
      return if ::ActiveRecord::Base.logger.nil?

      info = ''
      if ::ActiveRecord::Base.colorize_logging
        identifier_color, message_color = "4;32;1", "0" # 0;1 = Bold
        info << "  \e[#{identifier_color}m#{identifier}\e[0m   "
        info << "\e[#{message_color}m#{message}\e[0m"
      else
        info = "#{identifier}   #{message}"
      end

      ::ActiveRecord::Base.logger.send method, info
    end

    def log(*args)
      self.class.log(*args)
    end

    def prepare(client)
      index_options = {}
      if one_class && one_class.sphinx_indexes && one_class.sphinx_indexes.first
        index_options = one_class.sphinx_indexes.first.local_options
      end

      [
        :max_matches, :group_by, :group_function, :group_clause,
        :group_distinct, :id_range, :cut_off, :retry_count, :retry_delay,
        :rank_mode, :max_query_time, :field_weights
      ].each do |key|
        value = options[key] || index_options[key]
        client.send("#{key}=", value) if value
      end

      # treated non-standard as :select is already used for AR queries
      client.select = options[:sphinx_select] || '*'

      client.limit      = per_page
      client.offset     = offset
      client.match_mode = match_mode
      client.filters    = filters
      client.sort_mode  = sort_mode
      client.sort_by    = sort_by
      client.group_by   = group_by if group_by
      client.group_function = group_function if group_function
      client.index_weights  = index_weights
      client.anchor     = anchor

      client
    end

    def retry_on_stale_index(&block)
      stale_ids = []
      retries   = stale_retries

      begin
        options[:raise_on_stale] = retries > 0
        block.call

        # If ThinkingSphinx::Search#instances_from_matches found records in
        # Sphinx but not in the DB and the :raise_on_stale option is set, this
        # exception is raised. We retry a limited number of times, excluding the
        # stale ids from the search.
      rescue StaleIdsException => err
        retries -= 1

        # For logging
        stale_ids |= err.ids
        # ID exclusion
        options[:without_ids] = Array(options[:without_ids]) | err.ids

        log 'Sphinx Stale Ids (%s %s left): %s' % [
          retries, (retries == 1 ? 'try' : 'tries'), stale_ids.join(', ')
        ]
        retry
      end
    end

    def classes
      @classes ||= options[:classes] || []
    end

    def one_class
      @one_class ||= classes.length != 1 ? nil : classes.first
    end

    def query
      @query ||= begin
        q = @args.join(' ') << conditions_as_query
        (options[:star] ? star_query(q) : q).strip
      end
    end

    def conditions_as_query
      return '' if @options[:conditions].blank?

      ' ' + @options[:conditions].keys.collect { |key|
        "@#{key} #{options[:conditions][key]}"
      }.join(' ')
    end

    def star_query(query)
      token = options[:star].is_a?(Regexp) ? options[:star] : default_star_token

      query.gsub(/("#{token}(.*?#{token})?"|(?![!-])#{token})/u) do
        pre, proper, post = $`, $&, $'
        # E.g. "@foo", "/2", "~3", but not as part of a token
        is_operator = pre.match(%r{(\W|^)[@~/]\Z}) ||
                      pre.match(%r{(\W|^)@\([^\)]*$})
        # E.g. "foo bar", with quotes
        is_quote    = proper.starts_with?('"') && proper.ends_with?('"')
        has_star    = pre.ends_with?("*") || post.starts_with?("*")
        if is_operator || is_quote || has_star
          proper
        else
          "*#{proper}*"
        end
      end
    end

    if Regexp.instance_methods.include?(:encoding)
      DefaultStarToken = Regexp.new('\p{Word}+')
    else
      DefaultStarToken = Regexp.new('\w+', nil, 'u')
    end

    def default_star_token
      DefaultStarToken
    end

    def comment
      options[:comment] || ''
    end

    def match_mode
      options[:match_mode] || (options[:conditions].blank? ? :all : :extended)
    end

    def sort_mode
      @sort_mode ||= case options[:sort_mode]
      when :asc
        :attr_asc
      when :desc
        :attr_desc
      when nil
        case options[:order]
        when String
          :extended
        when Symbol
          :attr_asc
        else
          :relevance
        end
      else
        options[:sort_mode]
      end
    end

    def sort_by
      case @sort_by = (options[:sort_by] || options[:order])
      when String
        sorted_fields_to_attributes(@sort_by.clone)
      when Symbol
        field_names.include?(@sort_by) ?
          @sort_by.to_s.concat('_sort') : @sort_by.to_s
      else
        ''
      end
    end

    def field_names
      return [] unless one_class

      one_class.sphinx_indexes.collect { |index|
        index.fields.collect { |field| field.unique_name }
      }.flatten
    end

    def sorted_fields_to_attributes(order_string)
      field_names.each { |field|
        order_string.gsub!(/(^|\s)#{field}(,?\s|$)/) { |match|
          match.gsub field.to_s, field.to_s.concat("_sort")
        }
      }

      order_string
    end

    # Turn :index_weights => { "foo" => 2, User => 1 } into :index_weights =>
    # { "foo" => 2, "user_core" => 1, "user_delta" => 1 }
    #
    def index_weights
      weights = options[:index_weights] || {}
      weights.keys.inject({}) do |hash, key|
        if key.is_a?(Class)
          name = ThinkingSphinx::Index.name_for(key)
          hash["#{name}_core"]  = weights[key]
          hash["#{name}_delta"] = weights[key]
        else
          hash[key] = weights[key]
        end

        hash
      end
    end

    def group_by
      options[:group] ? options[:group].to_s : nil
    end

    def group_function
      options[:group] ? :attr : nil
    end

    def internal_filters
      filters = [Riddle::Client::Filter.new('sphinx_deleted', [0])]

      class_crcs = classes.collect { |klass|
        klass.to_crc32s
      }.flatten

      unless class_crcs.empty?
        filters << Riddle::Client::Filter.new('class_crc', class_crcs)
      end

      filters << Riddle::Client::Filter.new(
        'sphinx_internal_id', filter_value(options[:without_ids]), true
      ) unless options[:without_ids].nil? || options[:without_ids].empty?

      filters
    end

    def filters
      internal_filters +
      (options[:with] || {}).collect { |attrib, value|
        Riddle::Client::Filter.new attrib.to_s, filter_value(value)
      } +
      (options[:without] || {}).collect { |attrib, value|
        Riddle::Client::Filter.new attrib.to_s, filter_value(value), true
      } +
      (options[:with_all] || {}).collect { |attrib, values|
        Array(values).collect { |value|
          Riddle::Client::Filter.new attrib.to_s, filter_value(value)
        }
      }.flatten +
      (options[:without_any] || {}).collect { |attrib, values|
        Array(values).collect { |value|
          Riddle::Client::Filter.new attrib.to_s, filter_value(value), true
        }
      }.flatten
    end

    # When passed a Time instance, returns the integer timestamp.
    def filter_value(value)
      case value
      when Range
        filter_value(value.first).first..filter_value(value.last).first
      when Array
        value.collect { |v| filter_value(v) }.flatten
      when Time
        [value.to_i]
      when NilClass
        0
      else
        Array(value)
      end
    end

    def anchor
      return {} unless options[:geo] || (options[:lat] && options[:lng])

      {
        :latitude   => options[:geo] ? options[:geo].first : options[:lat],
        :longitude  => options[:geo] ? options[:geo].last  : options[:lng],
        :latitude_attribute  => latitude_attr.to_s,
        :longitude_attribute => longitude_attr.to_s
      }
    end

    def latitude_attr
      options[:latitude_attr]      ||
      index_option(:latitude_attr) ||
      attribute(:lat, :latitude)
    end

    def longitude_attr
      options[:longitude_attr]      ||
      index_option(:longitude_attr) ||
      attribute(:lon, :lng, :longitude)
    end

    def index_option(key)
      return nil unless one_class

      one_class.sphinx_indexes.collect { |index|
        index.local_options[key]
      }.compact.first
    end

    def attribute(*keys)
      return nil unless one_class

      keys.detect { |key|
        attributes.include?(key)
      }
    end

    def attributes
      return [] unless one_class

      attributes = one_class.sphinx_indexes.collect { |index|
        index.attributes.collect { |attrib| attrib.unique_name }
      }.flatten
    end

    def stale_retries
      case options[:retry_stale]
      when TrueClass
        3
      when nil, FalseClass
        0
      else
        options[:retry_stale].to_i
      end
    end

    def include_for_class(klass)
      includes = options[:include] || klass.sphinx_index_options[:include]

      case includes
      when NilClass
        nil
      when Array
        include_from_array includes, klass
      when Symbol
        klass.reflections[includes].nil? ? nil : includes
      when Hash
        include_from_hash includes, klass
      else
        includes
      end
    end

    def include_from_array(array, klass)
      scoped_array = []
      array.each do |value|
        case value
        when Hash
          scoped_hash = include_from_hash(value, klass)
          scoped_array << scoped_hash unless scoped_hash.nil?
        else
          scoped_array << value unless klass.reflections[value].nil?
        end
      end
      scoped_array.empty? ? nil : scoped_array
    end

    def include_from_hash(hash, klass)
      scoped_hash = {}
      hash.keys.each do |key|
        scoped_hash[key] = hash[key] unless klass.reflections[key].nil?
      end
      scoped_hash.empty? ? nil : scoped_hash
    end

    def instances_from_class(klass, matches)
      index_options = klass.sphinx_index_options

      ids = matches.collect { |match| match[:attributes]["sphinx_internal_id"] }
      instances = ids.length > 0 ? klass.find(
        :all,
        :joins      => options[:joins],
        :conditions => {klass.primary_key_for_sphinx.to_sym => ids},
        :include    => include_for_class(klass),
        :select     => (options[:select]  || index_options[:select]),
        :order      => (options[:sql_order] || index_options[:sql_order])
      ) : []

      # Raise an exception if we find records in Sphinx but not in the DB, so
      # the search method can retry without them. See
      # ThinkingSphinx::Search.retry_search_on_stale_index.
      if options[:raise_on_stale] && instances.length < ids.length
        stale_ids = ids - instances.map { |i| i.id }
        raise StaleIdsException, stale_ids
      end

      # if the user has specified an SQL order, return the collection
      # without rearranging it into the Sphinx order
      return instances if (options[:sql_order] || index_options[:sql_order])

      ids.collect { |obj_id|
        instances.detect do |obj|
          obj.primary_key_for_sphinx == obj_id
        end
      }
    end

    # Group results by class and call #find(:all) once for each group to reduce
    # the number of #find's in multi-model searches.
    #
    def instances_from_matches
      return single_class_results if one_class

      groups = results[:matches].group_by { |match|
        match[:attributes][crc_attribute]
      }
      groups.each do |crc, group|
        group.replace(
          instances_from_class(class_from_crc(crc), group)
        )
      end

      results[:matches].collect do |match|
        groups.detect { |crc, group|
          crc == match[:attributes][crc_attribute]
        }[1].compact.detect { |obj|
          obj.primary_key_for_sphinx == match[:attributes]["sphinx_internal_id"]
        }
      end
    end

    def single_class_results
      instances_from_class one_class, results[:matches]
    end

    def class_from_crc(crc)
      if Riddle.loaded_version.to_i < 2
        config.models_by_crc[crc].constantize
      else
        crc.constantize
      end
    end

    def each_with_attribute(attribute, &block)
      populate
      results[:matches].each_with_index do |match, index|
        yield self[index],
          (match[:attributes][attribute] || match[:attributes]["@#{attribute}"])
      end
    end

    def is_scope?(method)
      one_class && one_class.sphinx_scopes.include?(method)
    end

    # Adds the default_sphinx_scope if set.
    def add_default_scope
      return unless one_class && one_class.has_default_sphinx_scope?
      add_scope(one_class.get_default_sphinx_scope.to_sym)
    end

    def add_scope(method, *args, &block)
      method = "#{method}_without_default".to_sym
      merge_search one_class.send(method, *args, &block), self.args, options
    end

    def merge_search(search, args, options)
      search.args.each { |arg| args << arg }

      search.options.keys.each do |key|
        if HashOptions.include?(key)
          options[key] ||= {}
          options[key].merge! search.options[key]
        elsif ArrayOptions.include?(key)
          options[key] ||= []
          options[key] += search.options[key]
          options[key].uniq!
        else
          options[key] = search.options[key]
        end
      end
    end

    def scoped_count
      return self.total_entries if(@options[:ids_only] || @options[:only])

      @options[:ids_only] = true
      results_count = self.total_entries
      @options[:ids_only] = false
      @populated = false

      results_count
    end

    def crc_attribute
      Riddle.loaded_version.to_i < 2 ? 'class_crc' : 'sphinx_internal_class'
    end
  end
end
