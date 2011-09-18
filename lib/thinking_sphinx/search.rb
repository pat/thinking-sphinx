class ThinkingSphinx::Search < Array
  CoreMethods = %w( == class class_eval extend frozen? id instance_eval
    instance_of? instance_values instance_variable_defined?
    instance_variable_get instance_variable_set instance_variables is_a?
    kind_of? member? method methods nil? object_id respond_to?
    respond_to_missing? send should should_not type )
  SafeMethods = %w( partition private_methods protected_methods public_methods
    send class )

  instance_methods.select { |method|
    method.to_s[/^__/].nil? && !CoreMethods.include?(method.to_s)
  }.each { |method|
    undef_method method
  }

  attr_reader :options

  def initialize(query = nil, options = {})
    query, options   = nil, query if query.is_a?(Hash)
    @query, @options = query, options
    @array           = []
  end

  def current_page
    @options[:page] = 1 if @options[:page].blank?
    @options[:page].to_i
  end

  def first_page?
    current_page == 1
  end

  def last_page?
    next_page.nil?
  end

  def next_page
    current_page >= total_pages ? nil : current_page + 1
  end

  def next_page?
    !next_page.nil?
  end

  def offset
    @options[:offset] || ((current_page - 1) * per_page)
  end

  def page(number)
    @options[:page] = number
    self
  end

  def per(limit)
    @options[:limit] = limit
    self
  end

  def per_page
    @options[:limit] ||= (@options[:per_page] || 20)
    @options[:limit].to_i
  end

  def populate
    return if @populated

    @raw = connection.query(sphinxql_select.to_sql)
    @array.replace @raw.collect { |row|
      row['sphinx_internal_class'].constantize.find row['sphinx_internal_id']
    }
    @populated = true
  end

  def populate_meta
    return if @populated_meta

    populate
    @meta = connection.query(Riddle::Query.meta).inject({}) { |hash, row|
      hash[row['Variable_name']] = row['Value']
      hash
    }
    @populated_meta = true
  end

  def previous_page
    current_page == 1 ? nil : current_page - 1
  end

  def respond_to?(method, include_private = false)
    super || @array.respond_to?(method, include_private)
  end

  def total_entries
    populate_meta

    @meta['total_found'].to_i
  end

  def total_pages
    populate_meta
    return 0 if @meta['total'].nil?

    @total_pages ||= (@meta['total'].to_i / per_page.to_f).ceil
  end

  # For Kaminari and Will Paginate
  alias_method :limit_value, :per_page
  alias_method :page_count,  :total_pages
  alias_method :num_pages,   :total_pages
  alias_method :total_count, :total_entries

  private

  def classes
    options[:classes] || []
  end

  def config
    ThinkingSphinx::Configuration.instance
  end

  def connection
    @connection ||= Riddle::Query.connection(
      (config.searchd.address || '127.0.0.1'), config.searchd.mysql41
    )
  end

  def extended_query
    @options[:conditions] ||= {}
    @extended_query       ||= begin
      (@query.to_s + ' ' + @options[:conditions].keys.collect { |key|
        "@#{key} #{@options[:conditions][key]}"
      }.join(' ')).strip
    end
  end

  def filters
    @options[:with] || {}
  end

  def method_missing(method, *args, &block)
    populate if !SafeMethods.include?(method.to_s)

    @array.send(method, *args, &block)
  end

  def order_clause
    case @options[:order]
    when Symbol
      "#{@options[:order]} ASC"
    else
      @options[:order]
    end
  end

  def sphinxql_select
    Riddle::Query::Select.new.tap do |select|
      select.from(*indices)
      select.matching(extended_query) if extended_query.present?
      select.where(filters) if filters.any?
      select.order_by(order_clause) if order_clause.present?
      select.offset(offset)
      select.limit(per_page)
    end
  end

  def indices
    return config.indices.collect(&:name) if classes.empty?

    classes.collect { |klass|
      config.indices_for_reference(klass.name.underscore.to_sym).collect &:name
    }.flatten
  end
end
