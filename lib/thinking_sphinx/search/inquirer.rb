class ThinkingSphinx::Search::Inquirer
  SelectOptions = [:field_weights, :ranker]

  def initialize(search)
    @search = search
  end

  def indices
    config.preload_indices
    return config.indices.collect(&:name) if classes.empty?

    config.indices_for_references(*references).collect &:name
  end

  def meta
    @meta ||= connection.query(Riddle::Query.meta).inject({}) { |hash, row|
      hash[row['Variable_name']] = row['Value']
      hash
    }
  end

  def populate
    log :query, sphinxql do
      raw and meta
    end
    total = meta['total_found']
    log :message, "Found #{total} result#{'s' unless total == 1}"

    self
  end

  def raw
    @raw ||= connection.query(sphinxql)
  end

  private

  def ancestors
    classes_and_ancestors - classes
  end

  def classes
    options[:classes] || []
  end

  def classes_and_ancestors
    @classes_and_ancestors ||= classes.collect { |model|
      model.ancestors.take_while { |klass|
        klass != ActiveRecord::Base
      }.select { |klass|
        klass.class == Class
      }
    }.flatten
  end

  def classes_and_descendants
    classes + descendants
  end

  def class_condition
    '(' + classes_and_descendants.collect(&:name).join('|') + ')'
  end

  def config
    ThinkingSphinx::Configuration.instance
  end

  def connection
    @connection ||= config.connection
  end

  def descendants
    @descendants ||= classes.select { |klass|
      klass.column_names.include?(klass.inheritance_column)
    }.collect { |klass|
      klass.connection.select_values(<<-SQL).compact.each(&:constantize)
SELECT DISTINCT #{klass.inheritance_column}
FROM #{klass.table_name}
      SQL
      klass.descendants
    }.flatten
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
    conditions[:sphinx_internal_class] = class_condition if classes.any?
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

  def log(notification, message, &block)
    ActiveSupport::Notifications.instrument(
      "#{notification}.thinking_sphinx", notification => message, &block
    )
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

  def references
    classes_and_ancestors.collect { |klass|
      klass.name.underscore.to_sym
    }
  end

  def select_options
    @select_options ||= options.keys.inject({}) do |hash, key|
      hash[key] = options[key] if SelectOptions.include?(key)
      hash
    end
  end

  def sphinxql
    @sphinxql ||= sphinxql_select.to_sql
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
