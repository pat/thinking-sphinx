require 'riddle/client/filter'
require 'riddle/client/message'
require 'riddle/client/response'

module Riddle
  class VersionError < StandardError;  end
  class ResponseError < StandardError; end
  class OutOfBoundsError < StandardError; end

  # This class was heavily based on the existing Client API by Dmytro Shteflyuk
  # and Alexy Kovyrin. Their code worked fine, I just wanted something a bit
  # more Ruby-ish (ie. lowercase and underscored method names). I also have
  # used a few helper classes, just to neaten things up.
  #
  # Feel free to use it wherever. Send bug reports, patches, comments and
  # suggestions to pat at freelancing-gods dot com.
  #
  # Most properties of the client are accessible through attribute accessors,
  # and where relevant use symboles instead of the long constants common in
  # other clients.
  # Some examples:
  #
  #   client.sort_mode  = :extended
  #   client.sort_by    = "birthday DESC"
  #   client.match_mode = :extended
  #
  # To add a filter, you will need to create a Filter object:
  #
  #   client.filters << Riddle::Client::Filter.new("birthday",
  #     Time.at(1975, 1, 1).to_i..Time.at(1985, 1, 1).to_i, false)
  #
  class Client
    Commands = {
      :search     => 0, # SEARCHD_COMMAND_SEARCH
      :excerpt    => 1, # SEARCHD_COMMAND_EXCERPT
      :update     => 2, # SEARCHD_COMMAND_UPDATE
      :keywords   => 3, # SEARCHD_COMMAND_KEYWORDS
      :persist    => 4, # SEARCHD_COMMAND_PERSIST
      :status     => 5, # SEARCHD_COMMAND_STATUS
      :query      => 6, # SEARCHD_COMMAND_QUERY
      :flushattrs => 7  # SEARCHD_COMMAND_FLUSHATTRS
    }

    Versions = {
      :search     => 0x113, # VER_COMMAND_SEARCH
      :excerpt    => 0x100, # VER_COMMAND_EXCERPT
      :update     => 0x101, # VER_COMMAND_UPDATE
      :keywords   => 0x100, # VER_COMMAND_KEYWORDS
      :status     => 0x100, # VER_COMMAND_STATUS
      :query      => 0x100, # VER_COMMAND_QUERY
      :flushattrs => 0x100  # VER_COMMAND_FLUSHATTRS
    }

    Statuses = {
      :ok      => 0, # SEARCHD_OK
      :error   => 1, # SEARCHD_ERROR
      :retry   => 2, # SEARCHD_RETRY
      :warning => 3  # SEARCHD_WARNING
    }

    MatchModes = {
      :all        => 0, # SPH_MATCH_ALL
      :any        => 1, # SPH_MATCH_ANY
      :phrase     => 2, # SPH_MATCH_PHRASE
      :boolean    => 3, # SPH_MATCH_BOOLEAN
      :extended   => 4, # SPH_MATCH_EXTENDED
      :fullscan   => 5, # SPH_MATCH_FULLSCAN
      :extended2  => 6  # SPH_MATCH_EXTENDED2
    }

    RankModes = {
      :proximity_bm25 => 0, # SPH_RANK_PROXIMITY_BM25
      :bm25           => 1, # SPH_RANK_BM25
      :none           => 2, # SPH_RANK_NONE
      :wordcount      => 3, # SPH_RANK_WORDCOUNT
      :proximity      => 4, # SPH_RANK_PROXIMITY
      :match_any      => 5, # SPH_RANK_MATCHANY
      :fieldmask      => 6, # SPH_RANK_FIELDMASK
      :sph04          => 7, # SPH_RANK_SPH04
      :total          => 8  # SPH_RANK_TOTAL
    }

    SortModes = {
      :relevance     => 0, # SPH_SORT_RELEVANCE
      :attr_desc     => 1, # SPH_SORT_ATTR_DESC
      :attr_asc      => 2, # SPH_SORT_ATTR_ASC
      :time_segments => 3, # SPH_SORT_TIME_SEGMENTS
      :extended      => 4, # SPH_SORT_EXTENDED
      :expr          => 5  # SPH_SORT_EXPR
    }

    AttributeTypes = {
      :integer    => 1, # SPH_ATTR_INTEGER
      :timestamp  => 2, # SPH_ATTR_TIMESTAMP
      :ordinal    => 3, # SPH_ATTR_ORDINAL
      :bool       => 4, # SPH_ATTR_BOOL
      :float      => 5, # SPH_ATTR_FLOAT
      :bigint     => 6, # SPH_ATTR_BIGINT
      :string     => 7, # SPH_ATTR_STRING
      :multi      => 0x40000000 # SPH_ATTR_MULTI
    }

    GroupFunctions = {
      :day      => 0, # SPH_GROUPBY_DAY
      :week     => 1, # SPH_GROUPBY_WEEK
      :month    => 2, # SPH_GROUPBY_MONTH
      :year     => 3, # SPH_GROUPBY_YEAR
      :attr     => 4, # SPH_GROUPBY_ATTR
      :attrpair => 5  # SPH_GROUPBY_ATTRPAIR
    }

    FilterTypes = {
      :values       => 0, # SPH_FILTER_VALUES
      :range        => 1, # SPH_FILTER_RANGE
      :float_range  => 2  # SPH_FILTER_FLOATRANGE
    }

    attr_accessor :servers, :port, :offset, :limit, :max_matches,
      :match_mode, :sort_mode, :sort_by, :weights, :id_range, :filters,
      :group_by, :group_function, :group_clause, :group_distinct, :cut_off,
      :retry_count, :retry_delay, :anchor, :index_weights, :rank_mode,
      :rank_expr, :max_query_time, :field_weights, :timeout, :overrides,
      :select, :connection, :key
    attr_reader :queue

    @@connection = nil

    def self.connection=(value)
      Riddle.mutex.synchronize do
        @@connection = value
      end
    end

    def self.connection
      @@connection
    end

    # Can instantiate with a specific server and port - otherwise it assumes
    # defaults of localhost and 3312 respectively. All other settings can be
    # accessed and changed via the attribute accessors.
    def initialize(servers = nil, port = nil, key = nil)
      Riddle.version_warning

      @servers = Array(servers || "localhost")
      @port   = port || 9312
      @socket = nil
      @key    = key

      reset

      @queue = []
    end

    # Reset attributes and settings to defaults.
    def reset
      # defaults
      @offset         = 0
      @limit          = 20
      @max_matches    = 1000
      @match_mode     = :all
      @sort_mode      = :relevance
      @sort_by        = ''
      @weights        = []
      @id_range       = 0..0
      @filters        = []
      @group_by       = ''
      @group_function = :day
      @group_clause   = '@group desc'
      @group_distinct = ''
      @cut_off        = 0
      @retry_count    = 0
      @retry_delay    = 0
      @anchor         = {}
      # string keys are index names, integer values are weightings
      @index_weights  = {}
      @rank_mode      = :proximity_bm25
      @rank_expr      = ''
      @max_query_time = 0
      # string keys are field names, integer values are weightings
      @field_weights  = {}
      @timeout        = 0
      @overrides      = {}
      @select         = "*"
    end

    # The searchd server to query.  Servers are removed from @server after a
    # Timeout::Error is hit to allow for fail-over.
    def server
      @servers.first
    end

    # Backwards compatible writer to the @servers array.
    def server=(server)
      @servers = server.to_a
    end

    # Set the geo-anchor point - with the names of the attributes that contain
    # the latitude and longitude (in radians), and the reference position.
    # Note that for geocoding to work properly, you must also set
    # match_mode to :extended. To sort results by distance, you will
    # need to set sort_by to '@geodist asc', and sort_mode to extended (as an
    # example). Sphinx expects latitude and longitude to be returned from you
    # SQL source in radians.
    #
    # Example:
    #   client.set_anchor('lat', -0.6591741, 'long', 2.530770)
    #
    def set_anchor(lat_attr, lat, long_attr, long)
      @anchor = {
        :latitude_attribute   => lat_attr,
        :latitude             => lat,
        :longitude_attribute  => long_attr,
        :longitude            => long
      }
    end

    # Append a query to the queue. This uses the same parameters as the query
    # method.
    def append_query(search, index = '*', comments = '')
      @queue << query_message(search, index, comments)
    end

    # Run all the queries currently in the queue. This will return an array of
    # results hashes.
    def run
      response = Response.new request(:search, @queue)

      results = @queue.collect do
        result = {
          :matches         => [],
          :fields          => [],
          :attributes      => {},
          :attribute_names => [],
          :words           => {}
        }

        result[:status] = response.next_int
        case result[:status]
        when Statuses[:warning]
          result[:warning] = response.next
        when Statuses[:error]
          result[:error] = response.next
          next result
        end

        result[:fields] = response.next_array

        attributes = response.next_int
        attributes.times do
          attribute_name = response.next
          type           = response.next_int

          result[:attributes][attribute_name] = type
          result[:attribute_names] << attribute_name
        end

        result_attribute_names_and_types = result[:attribute_names].
          inject([]) { |array, attr| array.push([ attr, result[:attributes][attr] ]) }

        matches   = response.next_int
        is_64_bit = response.next_int

        result[:matches] = (0...matches).map do |i|
          doc = is_64_bit > 0 ? response.next_64bit_int : response.next_int
          weight = response.next_int

          current_match_attributes = {}

          result_attribute_names_and_types.each do |attr, type|
            current_match_attributes[attr] = attribute_from_type(type, response)
          end

          {:doc => doc, :weight => weight, :index => i, :attributes => current_match_attributes}
        end

        result[:total] = response.next_int.to_i || 0
        result[:total_found] = response.next_int.to_i || 0
        result[:time] = ('%.3f' % (response.next_int / 1000.0)).to_f || 0.0

        words = response.next_int
        words.times do
          word = response.next
          docs = response.next_int
          hits = response.next_int
          result[:words][word] = {:docs => docs, :hits => hits}
        end

        result
      end

      @queue.clear
      results
    end

    # Query the Sphinx daemon - defaulting to all indices, but you can specify
    # a specific one if you wish. The search parameter should be a string
    # following Sphinx's expectations.
    #
    # The object returned from this method is a hash with the following keys:
    #
    # * :matches
    # * :fields
    # * :attributes
    # * :attribute_names
    # * :words
    # * :total
    # * :total_found
    # * :time
    # * :status
    # * :warning (if appropriate)
    # * :error (if appropriate)
    #
    # The key <tt>:matches</tt> returns an array of hashes - the actual search
    # results. Each hash has the document id (<tt>:doc</tt>), the result
    # weighting (<tt>:weight</tt>), and a hash of the attributes for the
    # document (<tt>:attributes</tt>).
    #
    # The <tt>:fields</tt> and <tt>:attribute_names</tt> keys return list of
    # fields and attributes for the documents. The key <tt>:attributes</tt>
    # will return a hash of attribute name and type pairs, and <tt>:words</tt>
    # returns a hash of hashes representing the words from the search, with the
    # number of documents and hits for each, along the lines of:
    #
    #   results[:words]["Pat"] #=> {:docs => 12, :hits => 15}
    #
    # <tt>:total</tt>, <tt>:total_found</tt> and <tt>:time</tt> return the
    # number of matches available, the total number of matches (which may be
    # greater than the maximum available, depending on the number of matches
    # and your sphinx configuration), and the time in milliseconds that the
    # query took to run.
    #
    # <tt>:status</tt> is the error code for the query - and if there was a
    # related warning, it will be under the <tt>:warning</tt> key. Fatal errors
    # will be described under <tt>:error</tt>.
    #
    def query(search, index = '*', comments = '')
      @queue << query_message(search, index, comments)
      self.run.first
    end

    # Build excerpts from search terms (the +words+) and the text of documents. Excerpts are bodies of text that have the +words+ highlighted.
    # They may also be abbreviated to fit within a word limit.
    #
    # As part of the options hash, you will need to
    # define:
    # * :docs
    # * :words
    # * :index
    #
    # Optional settings include:
    # * :before_match (defaults to <span class="match">)
    # * :after_match (defaults to </span>)
    # * :chunk_separator (defaults to ' &#8230; ' - which is an HTML ellipsis)
    # * :limit (defaults to 256)
    # * :around (defaults to 5)
    # * :exact_phrase (defaults to false)
    # * :single_passage (defaults to false)
    #
    # The defaults differ from the official PHP client, as I've opted for
    # semantic HTML markup.
    #
    # Example:
    #
    #   client.excerpts(:docs => ["Pat Allan, Pat Cash"], :words => 'Pat', :index => 'pats')
    #   #=> ["<span class=\"match\">Pat</span> Allan, <span class=\"match\">Pat</span> Cash"]
    #
    #   lorem_lipsum = "Lorem ipsum dolor..."
    #
    #   client.excerpts(:docs => ["Pat Allan, #{lorem_lipsum} Pat Cash"], :words => 'Pat', :index => 'pats')
    #   #=> ["<span class=\"match\">Pat</span> Allan, Lorem ipsum dolor sit amet, consectetur adipisicing
    #          elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua &#8230; . Excepteur
    #          sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est
    #          laborum. <span class=\"match\">Pat</span> Cash"]
    #
    # Workflow:
    #
    # Excerpt creation is completely isolated from searching the index. The nominated index is only used to
    # discover encoding and charset information.
    #
    # Therefore, the workflow goes:
    #
    # 1. Do the sphinx query.
    # 2. Fetch the documents found by sphinx from their repositories.
    # 3. Pass the documents' text to +excerpts+ for marking up of matched terms.
    #
    def excerpts(options = {})
      options[:index]                ||= '*'
      options[:before_match]         ||= '<span class="match">'
      options[:after_match]          ||= '</span>'
      options[:chunk_separator]      ||= ' &#8230; ' # ellipsis
      options[:limit]                ||= 256
      options[:limit_passages]       ||= 0
      options[:limit_words]          ||= 0
      options[:around]               ||= 5
      options[:exact_phrase]         ||= false
      options[:single_passage]       ||= false
      options[:query_mode]           ||= false
      options[:force_all_words]      ||= false
      options[:start_passage_id]     ||= 1
      options[:load_files]           ||= false
      options[:html_strip_mode]      ||= 'index'
      options[:allow_empty]          ||= false
      options[:passage_boundary]     ||= 'none'
      options[:emit_zones]           ||= false
      options[:load_files_scattered] ||= false

      response = Response.new request(:excerpt, excerpts_message(options))

      options[:docs].collect { response.next }
    end

    # Update attributes - first parameter is the relevant index, second is an
    # array of attributes to be updated, and the third is a hash, where the
    # keys are the document ids, and the values are arrays with the attribute
    # values - in the same order as the second parameter.
    #
    # Example:
    #
    #   client.update('people', ['birthday'], {1 => [Time.at(1982, 20, 8).to_i]})
    #
    def update(index, attributes, values_by_doc)
      response = Response.new request(
        :update,
        update_message(index, attributes, values_by_doc)
      )

      response.next_int
    end

    # Generates a keyword list for a given query. Each keyword is represented
    # by a hash, with keys :tokenised and :normalised. If return_hits is set to
    # true it will also report on the number of hits and documents for each
    # keyword (see :hits and :docs keys respectively).
    def keywords(query, index, return_hits = false)
      response = Response.new request(
        :keywords,
        keywords_message(query, index, return_hits)
      )

      (0...response.next_int).collect do
        hash = {}
        hash[:tokenised]  = response.next
        hash[:normalised] = response.next

        if return_hits
          hash[:docs] = response.next_int
          hash[:hits] = response.next_int
        end

        hash
      end
    end

    def status
      response = Response.new request(
        :status, Message.new
      )

      rows, cols = response.next_int, response.next_int

      (0...rows).inject({}) do |hash, row|
        hash[response.next.to_sym] = response.next
        hash
      end
    end

    def flush_attributes
      response = Response.new request(
        :flushattrs, Message.new
      )

      response.next_int
    end

    def add_override(attribute, type, values)
      @overrides[attribute] = {:type => type, :values => values}
    end

    def open
      open_socket

      return if Versions[:search] < 0x116

      @socket.send [
        Commands[:persist], 0, 4, 1
      ].pack("nnNN"), 0
    end

    def close
      close_socket
    end

    private

    def open_socket
      raise "Already Connected" unless @socket.nil?

      if @timeout == 0
        @socket = initialise_connection
      else
        begin
          Timeout.timeout(@timeout) { @socket = initialise_connection }
        rescue Timeout::Error, Riddle::ConnectionError => e
          failed_servers ||= []
          failed_servers << servers.shift
          retry if !servers.empty?

          case e
          when Timeout::Error
            raise Riddle::ConnectionError,
              "Connection to #{failed_servers.inspect} on #{@port} timed out after #{@timeout} seconds"
          else
            raise e
          end
        end
      end

      true
    end

    def close_socket
      raise "Not Connected" if @socket.nil?

      @socket.close
      @socket = nil

      true
    end

    # If there's an active connection to the Sphinx daemon, this will yield the
    # socket. If there's no active connection, then it will connect, yield the
    # new socket, then close it.
    def connect(&block)
      if @socket.nil? || @socket.closed?
        @socket = nil
        open_socket
        begin
          yield @socket
        ensure
          close_socket
        end
      else
        yield @socket
      end
    end

    def initialise_connection
      socket = initialise_socket

      # Checking version
      version = socket.recv(4).unpack('N*').first
      if version < 1
        socket.close
        raise VersionError, "Can only connect to searchd version 1.0 or better, not version #{version}"
      end

      # Send version
      socket.send [1].pack('N'), 0

      socket
    end

    def initialise_socket
      tries = 0
      begin
        socket = if self.connection
          self.connection.call(self)
        elsif self.class.connection
          self.class.connection.call(self)
        elsif server.index('/') == 0
          UNIXSocket.new server
        else
          TCPSocket.new server, @port
        end
      rescue Errno::ETIMEDOUT, Errno::ECONNRESET, Errno::ECONNREFUSED => e
        retry if (tries += 1) < 5
        raise Riddle::ConnectionError,
          "Connection to #{server} on #{@port} failed. #{e.message}"
      end

      socket
    end

    def request_header(command, length = 0)
      length += key_message.length if key
      core_header = case command
      when :search
        # Message length is +4/+8 to account for the following count value for
        # the number of messages.
        if Versions[command] >= 0x118
          [Commands[command], Versions[command], 8 + length].pack("nnN")
        else
          [Commands[command], Versions[command], 4 + length].pack("nnN")
        end
      when :status
        [Commands[command], Versions[command], 4, 1].pack("nnNN")
      else
        [Commands[command], Versions[command], length].pack("nnN")
      end

      key ? core_header + key_message : core_header
    end

    def key_message
      @key_message ||= begin
        message = Message.new
        message.append_string key
        message.to_s
      end
    end

    # Send a collection of messages, for a command type (eg, search, excerpts,
    # update), to the Sphinx daemon.
    def request(command, messages)
      response = ""
      status   = -1
      version  = 0
      length   = 0
      message  = Riddle.encode(Array(messages).join(""), 'ASCII-8BIT')

      connect do |socket|
        case command
        when :search
          if Versions[command] >= 0x118
            socket.send request_header(command, message.length) +
              [0, messages.length].pack('NN') + message, 0
          else
            socket.send request_header(command, message.length) +
              [messages.length].pack('N') + message, 0
          end
        when :status
          socket.send request_header(command, message.length), 0
        else
          socket.send request_header(command, message.length) + message, 0
        end

        header = socket.recv(8)
        status, version, length = header.unpack('n2N')

        while response.length < (length || 0)
          part = socket.recv(length - response.length)

          # will return 0 bytes if remote side closed TCP connection, e.g, searchd segfaulted.
          break if part.length == 0 && socket.is_a?(TCPSocket)

          response << part if part
        end
      end

      if response.empty? || response.length != length
        raise ResponseError, "No response from searchd (status: #{status}, version: #{version})"
      end

      case status
      when Statuses[:ok]
        if version < Versions[command]
          puts format("searchd command v.%d.%d older than client (v.%d.%d)",
            version >> 8, version & 0xff,
            Versions[command] >> 8, Versions[command] & 0xff)
        end
        response
      when Statuses[:warning]
        length = response[0, 4].unpack('N*').first
        puts response[4, length]
        response[4 + length, response.length - 4 - length]
      when Statuses[:error], Statuses[:retry]
        message = response[4, response.length - 4]
        klass = message[/out of bounds/] ? OutOfBoundsError : ResponseError
        raise klass, "searchd error (status: #{status}): #{message}"
      else
        raise ResponseError, "Unknown searchd error (status: #{status})"
      end
    end

    # Generation of the message to send to Sphinx for a search.
    def query_message(search, index, comments = '')
      message = Message.new

      # Mode, Limits
      message.append_ints @offset, @limit, MatchModes[@match_mode]

      # Ranking
      message.append_int RankModes[@rank_mode]
      message.append_string @rank_expr if @rank_mode == :expr

      # Sort Mode
      message.append_int SortModes[@sort_mode]
      message.append_string @sort_by

      # Query
      message.append_string search

      # Weights
      message.append_int @weights.length
      message.append_ints *@weights

      # Index
      message.append_string index

      # ID Range
      message.append_int 1
      message.append_64bit_ints @id_range.first, @id_range.last

      # Filters
      message.append_int @filters.length
      @filters.each { |filter| message.append filter.query_message }

      # Grouping
      message.append_int GroupFunctions[@group_function]
      message.append_string @group_by
      message.append_int @max_matches
      message.append_string @group_clause
      message.append_ints @cut_off, @retry_count, @retry_delay
      message.append_string @group_distinct

      # Anchor Point
      if @anchor.empty?
        message.append_int 0
      else
        message.append_int 1
        message.append_string @anchor[:latitude_attribute]
        message.append_string @anchor[:longitude_attribute]
        message.append_floats @anchor[:latitude], @anchor[:longitude]
      end

      # Per Index Weights
      message.append_int @index_weights.length
      @index_weights.each do |key,val|
        message.append_string key.to_s
        message.append_int val
      end

      # Max Query Time
      message.append_int @max_query_time

      # Per Field Weights
      message.append_int @field_weights.length
      @field_weights.each do |key,val|
        message.append_string key.to_s
        message.append_int val
      end

      message.append_string comments

      return message.to_s if Versions[:search] < 0x116

      # Overrides
      message.append_int @overrides.length
      @overrides.each do |key,val|
        message.append_string key.to_s
        message.append_int AttributeTypes[val[:type]]
        message.append_int val[:values].length
        val[:values].each do |id,map|
          message.append_64bit_int id
          method = case val[:type]
          when :float
            :append_float
          when :bigint
            :append_64bit_int
          else
            :append_int
          end
          message.send method, map
        end
      end

      message.append_string @select

      message.to_s
    end

    # Generation of the message to send to Sphinx for an excerpts request.
    def excerpts_message(options)
      message = Message.new

      message.append [0, excerpt_flags(options)].pack('N2') # 0 = mode
      message.append_string options[:index]
      message.append_string options[:words]

      # options
      message.append_string options[:before_match]
      message.append_string options[:after_match]
      message.append_string options[:chunk_separator]
      message.append_ints options[:limit], options[:around]

      message.append_array options[:docs]

      message.to_s
    end

    # Generation of the message to send to Sphinx to update attributes of a
    # document.
    def update_message(index, attributes, values_by_doc)
      message = Message.new

      message.append_string index
      message.append_array attributes

      message.append_int values_by_doc.length
      values_by_doc.each do |key,values|
        message.append_64bit_int key # document ID
        message.append_ints *values # array of new values (integers)
      end

      message.to_s
    end

    # Generates the simple message to send to the daemon for a keywords request.
    def keywords_message(query, index, return_hits)
      message = Message.new

      message.append_string query
      message.append_string index
      message.append_int return_hits ? 1 : 0

      message.to_s
    end

    AttributeHandlers = {
      AttributeTypes[:integer]   => :next_int,
      AttributeTypes[:timestamp] => :next_int,
      AttributeTypes[:ordinal]   => :next_int,
      AttributeTypes[:bool]      => :next_int,
      AttributeTypes[:float]     => :next_float,
      AttributeTypes[:bigint]    => :next_64bit_int,
      AttributeTypes[:string]    => :next,
      AttributeTypes[:multi] + AttributeTypes[:integer] => :next_int_array
    }

    def attribute_from_type(type, response)
      handler = AttributeHandlers[type]
      response.send handler
    end

    def excerpt_flags(options)
      flags = 1
      flags |= 2    if options[:exact_phrase]
      flags |= 4    if options[:single_passage]
      flags |= 8    if options[:use_boundaries]
      flags |= 16   if options[:weight_order]
      flags |= 32   if options[:query_mode]
      flags |= 64   if options[:force_all_words]
      flags |= 128  if options[:load_files]
      flags |= 256  if options[:allow_empty]
      flags |= 512  if options[:emit_zones]
      flags |= 1024 if options[:load_files_scattered]
      flags
    end
  end
end
