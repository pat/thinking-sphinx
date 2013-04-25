class ThinkingSphinx::Middlewares::SphinxQL <
  ThinkingSphinx::Middlewares::Middleware

  SELECT_OPTIONS = [:ranker, :max_matches, :cutoff, :max_query_time,
    :retry_count, :retry_delay, :field_weights, :index_weights, :reverse_scan,
    :comment]

  def call(contexts)
    contexts.each do |context|
      Inner.new(context).call
    end

    app.call contexts
  end

  private

  class Inner
    def initialize(context)
      @context = context
    end

    def call
      context[:indices]  = indices
      context[:sphinxql] = statement
    end

    private

    attr_reader :context

    def classes
      options[:classes] || []
    end

    def classes_and_descendants
      classes + descendants
    end

    def class_condition
      class_names = classes_and_descendants.collect(&:name).collect { |name|
        name[/:/] ? "\"#{name}\"" : name
      }
      '(' + class_names.join('|') + ')'
    end

    def descendants
      @descendants ||= options[:skip_sti] ? [] : descendants_from_tables
    end

    def descendants_from_tables
      classes.select { |klass|
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
      conditions[:sphinx_internal_class_name] = class_condition if classes.any?
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

    def index_options
      indices.first.options
    end

    def indices
      @indices ||= ThinkingSphinx::IndexSet.new classes, options[:indices]
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

    def select_options
      @select_options ||= SELECT_OPTIONS.inject({}) do |hash, key|
        hash[key] = settings[key.to_s] if settings.key? key.to_s
        hash[key] = index_options[key] if index_options.key? key
        hash[key] = options[key]       if options.key? key
        hash
      end
    end

    def settings
      context.configuration.settings
    end

    def statement
      Riddle::Query::Select.new.tap do |select|
        select.from *index_names.collect { |index| "`#{index}`" }
        select.values values                if values.present?
        select.matching extended_query      if extended_query.present?
        select.where inclusive_filters      if inclusive_filters.any?
        select.where_all options[:with_all] if options[:with_all]
        select.where_not exclusive_filters  if exclusive_filters.any?
        select.where_not_all options[:without_all] if options[:without_all]
        select.order_by order_clause        if order_clause.present?
        select.group_by group_attribute     if group_attribute.present?
        select.order_within_group_by group_order_clause if group_order_clause.present?
        select.offset context.search.offset
        select.limit  context.search.per_page
        select.with_options select_options  if select_options.keys.any?
      end
    end

    def values
      options[:select] ||= '*, @groupby, count(*) AS sphinx_count' if group_attribute.present?
      options[:select]
    end
  end
end
