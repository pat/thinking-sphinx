class ThinkingSphinx::Search < Array
  attr_reader :options

  def initialize(query = nil, options = {})
    @query, @options = query, options
  end

  def empty?
    populate
    super
  end

  def populate
    return if @populated

    replace connection.query(sphinxql_select.to_sql).collect { |row|
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

  def sphinxql_select
    Riddle::Query::Select.new.tap do |select|
      select.from(*indices)
    end
  end

  def indices
    classes.collect { |klass|
      config.indices_for_reference(klass.name.underscore.to_sym).collect &:name
    }.flatten
  end
end
