class ThinkingSphinx::Middlewares::SphinxQL <
  ThinkingSphinx::Middlewares::Middleware

  SELECT_OPTIONS = [:field_weights, :ranker]

  def call(context)
    @context           = context
    reset_memos

    context[:indices]  = indices
    context[:sphinxql] = statement

    if group_attribute.present?
      context.search.masks << ThinkingSphinx::Masks::GroupEnumeratorsMask
    end

    app.call context
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
      ThinkingSphinx::Search::Query.new(context.search.query, conditions,
        options[:star]).to_s
    end
  end

  def group_attribute
    options[:group_by] ? options[:group_by].to_s : nil
  end

  def group_order_clause
    case options[:order_group_by]
    when Symbol
      "#{options[:order_group_by]} ASC"
    else
      options[:order_group_by]
    end
  end

  def inclusive_filters
    @inclusive_filters ||= (options[:with] || {}).tap do |with|
      with[:sphinx_deleted] = false
    end
  end

  def index_names
    indices.collect(&:name)
  end

  def indices
    context.configuration.preload_indices
    return context.configuration.indices if classes.empty?

    context.configuration.indices_for_references(*references)
  end

  def options
    context.search.options
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

  def reset_memos
    @classes_and_ancestors = nil
    @descendants           = nil
    @exclusive_filters     = nil
    @extended_query        = nil
    @inclusive_filters     = nil
    @select_options        = nil
  end

  def select_options
    @select_options ||= options.keys.inject({}) do |hash, key|
      hash[key] = options[key] if SELECT_OPTIONS.include?(key)
      hash
    end
  end

  def statement
    Riddle::Query::Select.new.tap do |select|
      select.from *index_names.collect { |index| "`#{index}`" }
      select.values values               if values.present?
      select.matching extended_query     if extended_query.present?
      select.where inclusive_filters     if inclusive_filters.any?
      select.where_not exclusive_filters if exclusive_filters.any?
      select.order_by order_clause       if order_clause.present?
      select.group_by group_attribute    if group_attribute.present?
      select.order_within_group_by group_order_clause if group_order_clause.present?
      select.offset context.search.offset
      select.limit  context.search.per_page
      select.with_options select_options if select_options.keys.any?
    end
  end

  def values
    options[:select]
  end
end
