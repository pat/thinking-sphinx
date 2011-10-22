class ThinkingSphinx::Search < Array
  CoreMethods = %w( == class class_eval extend frozen? id instance_eval
    instance_of? instance_values instance_variable_defined?
    instance_variable_get instance_variable_set instance_variables is_a?
    kind_of? member? method methods nil? object_id respond_to?
    respond_to_missing? send should should_not type )
  SafeMethods = %w( partition private_methods protected_methods public_methods
    send class )
  SelectOptions = [:field_weights]

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

    populate if options[:populate]
  end

  def current_page
    @options[:page] = 1 if @options[:page].blank?
    @options[:page].to_i
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
    return self if @populated

    results_for_models # load now to avoid segfaults
    @array.replace raw.collect { |row| result_for_row row }
    @populated = true

    self
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

  def respond_to?(method, include_private = false)
    super || @array.respond_to?(method, include_private)
  end

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

  def indices
    config.preload_indices
    return config.indices.collect(&:name) if classes.empty?

    classes.collect { |klass|
      config.indices_for_reference(klass.name.underscore.to_sym).collect &:name
    }.flatten
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

  def raw
    @raw ||= connection.query(sphinxql_select.to_sql)
  end

  def result_for_row(row)
    results_for_models[row['sphinx_internal_class']].detect { |record|
      record.id == row['sphinx_internal_id']
    }
  end

  def result_ids_for_model(model_name)
    raw.select { |row|
      row['sphinx_internal_class'] == model_name
    }.collect { |row|
      row['sphinx_internal_id']
    }
  end

  def result_model_names
    @result_model_names ||= raw.collect { |row|
      row['sphinx_internal_class']
    }.uniq
  end

  def results_for_models
    @results_for_models ||= result_model_names.inject({}) { |hash, name|
      hash[name] = name.constantize.find result_ids_for_model(name)
      hash
    }
  end

  def select_options
    @select_options ||= options.keys.inject({}) do |hash, key|
      hash[key] = options[key] if SelectOptions.include?(key)
      hash
    end
  end

  def sphinxql_select
    Riddle::Query::Select.new.tap do |select|
      select.from *indices.collect { |index| "`#{index}`" }
      select.matching extended_query if extended_query.present?
      select.where filters if filters.any?
      select.order_by order_clause if order_clause.present?
      select.offset offset
      select.limit per_page
      select.with_options select_options if select_options.keys.any?
    end
  end
end

require 'thinking_sphinx/search/geodist'
require 'thinking_sphinx/search/pagination'

ThinkingSphinx::Search.send :include, ThinkingSphinx::Search::Geodist
ThinkingSphinx::Search.send :include, ThinkingSphinx::Search::Pagination
