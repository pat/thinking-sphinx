class ThinkingSphinx::ActiveRecord::PropertyQuery
  def initialize(property, source, type = nil)
    @property, @source, @type = property, source, type
  end

  def to_s
    if unsafe_habtm_column?
      raise <<-MESSAGE
Source queries cannot be used with HABTM joins if they use anything beyond the
primary key.
      MESSAGE
    end

    if safe_habtm_column?
      ThinkingSphinx::ActiveRecord::SimpleManyQuery.new(
        property, source, type
      ).to_s
    else
      "#{identifier} from #{source_type}; #{queries.join('; ')}"
    end
  end

  private

  attr_reader :property, :source, :type

  delegate :unscoped, :to => :base_association_class, :prefix => true

  def base_association
    reflections.first
  end

  def base_association_class
    base_association.klass
  end

  def column
    @column ||= property.columns.first
  end

  def extend_reflection(reflection)
    return [reflection] unless reflection.through_reflection

    [reflection.through_reflection, reflection.source_reflection]
  end

  def identifier
    [type, property.name].compact.join(' ')
  end

  def joins
    @joins ||= begin
      remainder = reflections.collect(&:name)[1..-1]
      return nil             if remainder.empty?
      return remainder.first if remainder.length == 1

      remainder[0..-2].reverse.inject(remainder.last) { |value, key|
        {key => value}
      }
    end
  end

  def macros
    reflections.collect &:macro
  end

  def offset
    "* #{ThinkingSphinx::Configuration.instance.indices.count} + #{source.offset}"
  end

  def queries
    queries    = []
    if column.string?
      queries << column.__name.strip.gsub(/\n/, "\\\n")
    else
      queries << to_sql
      queries << range_sql if ranged?
    end
    queries
  end

  def quoted_foreign_key
    quote_with_table(base_association_class.table_name, base_association.foreign_key)
  end

  def quoted_primary_key
    quote_with_table(reflections.last.klass.table_name, column.__name)
  end

  def quote_with_table(table, column)
    "#{quote_column(table)}.#{quote_column(column)}"
  end

  def quote_column(column)
    ActiveRecord::Base.connection.quote_column_name(column)
  end

  def ranged?
    property.source_type == :ranged_query
  end

  def range_sql
    base_association_class_unscoped.select(
      "MIN(#{quoted_foreign_key}), MAX(#{quoted_foreign_key})"
    ).to_sql
  end

  def reflections
    @reflections ||= begin
      base = source.model

      column.__stack.collect { |key|
        reflection = base.reflect_on_association key
        base = reflection.klass

        extend_reflection reflection
      }.flatten
    end
  end

  def safe_habtm_column?
    macros == [:has_and_belongs_to_many] && column.__name == :id
  end

  def source_type
    property.source_type.to_s.dasherize
  end

  def to_sql
    raise "Could not determine SQL for MVA" if reflections.empty?

    relation = base_association_class_unscoped.select("#{quoted_foreign_key} #{offset} AS #{quote_column('id')}, #{quoted_primary_key} AS #{quote_column(property.name)}")
    relation = relation.joins(joins) if joins.present?
    relation = relation.where("#{quoted_foreign_key} BETWEEN $start AND $end") if ranged?
    relation = relation.where("#{quoted_foreign_key} IS NOT NULL")
    relation = relation.order("#{quoted_foreign_key} ASC") if type.nil?

    relation.to_sql
  end

  def unsafe_habtm_column?
    macros.include?(:has_and_belongs_to_many) && (
      macros.length > 1 || column.__name != :id
    )
  end
end
