class ThinkingSphinx::Search::Inquirer
  SelectOptions = [:field_weights]

  def initialize(search)
    @search = search
  end

  def meta
    @meta ||= connection.query(Riddle::Query.meta).inject({}) { |hash, row|
      hash[row['Variable_name']] = row['Value']
      hash
    }
  end

  def populate
    raw and meta and self
  end

  def raw
    @raw ||= connection.query(sphinxql_select.to_sql)
  end

  private

  def classes
    options[:classes] || []
  end

  def config
    ThinkingSphinx::Configuration.instance
  end

  def connection
    @connection ||= config.connection
  end

  def exclusive_filters
    @exclusive_filters ||= (options[:without] || {}).tap do |without|
      if options[:without_ids].present? && options[:without_ids].any?
        without[:sphinx_internal_id] = options[:without_ids]
      end
    end
  end

  def extended_query
    conditions = options[:conditions] || {}
    @extended_query ||= begin
      (@search.query.to_s + ' ' + conditions.keys.collect { |key|
        "@#{key} #{conditions[key]}"
      }.join(' ')).strip
    end
  end

  def inclusive_filters
    @inclusive_filters ||= (options[:with] || {}).tap do |with|
      with[:sphinx_deleted] = false
    end
  end

  def indices
    config.preload_indices
    return config.indices.collect(&:name) if classes.empty?

    classes.collect { |klass|
      config.indices_for_reference(klass.name.underscore.to_sym).collect &:name
    }.flatten
  end

  def options
    @search.options
  end

  def order_clause
    case options[:order]
    when Symbol
      "#{options[:order]} ASC"
    else
      options[:order]
    end
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
      select.where inclusive_filters if inclusive_filters.any?
      select.where_not exclusive_filters if exclusive_filters.any?
      select.order_by order_clause if order_clause.present?
      select.offset @search.offset
      select.limit @search.per_page
      select.with_options select_options if select_options.keys.any?
    end
  end
end

ThinkingSphinx::Search::Inquirer.send :include, ThinkingSphinx::Search::Geodist
