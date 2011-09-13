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

  def populate
    return if @populated

    @array.replace connection.query(sphinxql_select.to_sql).collect { |row|
      row['sphinx_internal_class'].constantize.find row['sphinx_internal_id']
    }
    @populated = true
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

  def method_missing(method, *args, &block)
    populate if !SafeMethods.include?(method.to_s)

    @array.send(method, *args, &block)
  end

  def sphinxql_select
    Riddle::Query::Select.new.tap do |select|
      select.from(*indices)
      select.matching(extended_query) if extended_query.present?
      select.where(filters) if filters.any?
    end
  end

  def indices
    return config.indices.collect(&:name) if classes.empty?

    classes.collect { |klass|
      config.indices_for_reference(klass.name.underscore.to_sym).collect &:name
    }.flatten
  end
end
