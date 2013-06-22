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

    def classes_and_descendants_names
      classes_and_descendants.collect do |klass|
        name = klass.name
        name = %Q{"#{name}"} if name[/:/]
        name
      end
    end

    def classes_with_inheritance_column
      classes.select { |klass|
        klass.column_names.include?(klass.inheritance_column)
      }
    end

    def class_condition
      "(#{classes_and_descendants_names.join('|')})"
    end

    def descendants
      @descendants ||= options[:skip_sti] ? [] : descendants_from_tables
    end

    def descendants_from_tables
      classes_with_inheritance_column.collect { |klass|
        klass.connection.select_values(<<-SQL).compact.each(&:constantize)
  SELECT DISTINCT #{klass.inheritance_column}
  FROM #{klass.table_name}
        SQL
        klass.descendants
      }.flatten
    end

    def exclusive_filters
      @exclusive_filters ||= (options[:without] || {}).tap do |without|
        without[:sphinx_internal_id] = options[:without_ids] if options[:without_ids].present?
      end
    end

    def extended_query
      conditions = options[:conditions] || {}
      conditions[:sphinx_internal_class_name] = class_condition if classes.any?
      @extended_query ||= ThinkingSphinx::Search::Query.new(
        context.search.query, conditions, options[:star]
      ).to_s
    end

    def group_attribute
      options[:group_by].to_s if options[:group_by]
    end

    def group_order_clause
      group_by = options[:order_group_by]
      group_by = "#{group_by} ASC" if group_by.is_a? Symbol
      group_by
    end

    def inclusive_filters
      (options[:with] || {}).merge({:sphinx_deleted => false})
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

    delegate :search, :to => :context
    delegate :options, :to => :search

    def order_clause
      order_by = options[:order]
      order_by = "#{order_by} ASC" if order_by.is_a? Symbol
      order_by
    end

    def select_options
      @select_options ||= SELECT_OPTIONS.inject({}) do |hash, key|
        hash[key] = settings[key.to_s] if settings.key? key.to_s
        hash[key] = index_options[key] if index_options.key? key
        hash[key] = options[key]       if options.key? key
        hash
      end
    end

    delegate :configuration, :to => :context
    delegate :settings, :to => :configuration

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
      options[:select] ||= '*, @groupby, @count' if group_attribute.present?
      options[:select]
    end
  end
end
