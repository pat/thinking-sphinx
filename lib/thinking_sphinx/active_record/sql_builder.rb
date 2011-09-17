class ThinkingSphinx::ActiveRecord::SQLBuilder
  attr_reader :source

  def initialize(source)
    @source = source
  end

  def sql_query
    relation = model.unscoped
    relation = relation.select pre_select + select_clause
    relation = relation.where where_clause
    relation = relation.group group_clause
    relation = relation.order('NULL') if source.type == 'mysql'
    relation = relation.joins associations.join_values

    relation.to_sql
  end

  def sql_query_range
    return nil if source.disable_range?

    minimum = source.adapter.convert_nulls "MIN(#{quoted_primary_key})", 1
    maximum = source.adapter.convert_nulls "MAX(#{quoted_primary_key})", 1

    relation = source.model.unscoped
    relation = relation.select "#{minimum}, #{maximum}"
    relation = relation.where where_clause(true)

    relation.to_sql
  end

  def sql_query_info
    relation = source.model.unscoped
    relation.where("#{quoted_primary_key} = #{reversed_document_id}").to_sql
  end

  def sql_query_pre
    queries = []

    reset_delta = delta_processor && !source.delta?
    max_len     = source.options[:group_concat_max_len]

    queries << delta_processor.reset_query if reset_delta
    queries << "SET SESSION group_concat_max_len = #{max_len}" if max_len
    queries << adapter.utf8_query_pre if source.options[:utf8?]

    queries.compact
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end

  def model
    source.model
  end

  def base_join
    @base_join ||= join_dependency_class.new model, [], initial_joins
  end

  def delta_processor
    source.delta_processor
  end

  def associations
    @associations ||= ThinkingSphinx::ActiveRecord::Associations.new(model)
  end

  def quote_column(column)
    model.connection.quote_column_name(column)
  end

  def quoted_primary_key
    "#{model.quoted_table_name}.#{quote_column(model.primary_key_for_sphinx)}"
  end

  def quoted_inheritance_column
    "#{model.quoted_table_name}.#{quote_column model.inheritance_column}"
  end

  def pre_select
    source.type == 'mysql' ? 'SQL_NO_CACHE ' : ''
  end

  def document_id
    quoted_alias  = quote_column(model.primary_key_for_sphinx)
    "#{quoted_primary_key} * #{config.indices.count} + #{source.offset} AS #{quoted_alias}"
  end

  def reversed_document_id
    "($id - #{source.offset}) / #{config.indices.count}"
  end

  def select_clause
    (
      [document_id] +
      source.fields.collect     { |field|
        field.to_select_sql(associations)
      } +
      source.attributes.collect { |attribute|
        attribute.to_select_sql(associations)
      }
    ).compact.join(', ')
  end

  def where_clause(without_range = false)
    logic = []

    unless without_range || source.disable_range?
      logic << "#{quoted_primary_key} >= $start"
      logic << "#{quoted_primary_key} <= $end"
    end

    unless model.descends_from_active_record?
      klass = model.store_full_sti_class ? model.name : model.name.demodulize
      logic << "#{quoted_inheritance_column} = '#{klass}'"
    end

    logic << delta_processor.clause(source.delta?) if delta_processor
    logic += source.conditions

    logic.compact.join(' AND ')
  end

  def group_clause
    internal_groupings = []
    if model.column_names.include?(model.inheritance_column)
      internal_groupings << quoted_inheritance_column
    end

    (
      [quoted_primary_key] +
      source.fields.collect     { |field|
        field.to_group_sql(associations)
      }.compact +
      source.attributes.collect { |attribute|
        attribute.to_group_sql(associations)
      }.compact +
      source.groupings + internal_groupings
    ).join(', ')
  end

  # def all_associations
  #   []
  # end
  #
  # def join_dependency_class
  #   if rails_3_1?
  #     ::ActiveRecord::Associations::JoinDependency
  #   else
  #     ::ActiveRecord::Associations::ClassMethods::JoinDependency
  #   end
  # end
  #
  # def initial_joins
  #   if rails_3_1?
  #     []
  #   else
  #     nil
  #   end
  # end
  #
  # def rails_3_1?
  #   ::ActiveRecord::Associations.constants.include?(:JoinDependency) ||
  #   ::ActiveRecord::Associations.constants.include?('JoinDependency')
  # end
end
