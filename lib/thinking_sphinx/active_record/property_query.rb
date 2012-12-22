class ThinkingSphinx::ActiveRecord::PropertyQuery
  def initialize(property, source, type = nil)
    @property, @source, @type = property, source, type

    raise "Could not determine SQL for MVA" if reflections.empty?
  end

  def to_s
    identifier = [type, property.name].compact.join(' ')

    case property.source_type
    when :query
      "#{identifier} from query; #{to_sql}"
    when :ranged_query
      "#{identifier} from ranged-query; #{to_sql true}; #{range_sql}"
    else
      raise "Unsupported source type: #{property.source_type}"
    end
  end

  def range_sql
    base_association.klass.unscoped.
      select("MIN(#{quoted_foreign_key}), MAX(#{quoted_foreign_key})").to_sql
  end

  def to_sql(ranged = false)
    relation = base_association.klass.unscoped
    relation = relation.joins joins unless joins.blank?
    relation = relation.select "#{quoted_foreign_key} #{offset} AS #{quote_column('id')}, #{quoted_primary_key} AS #{quote_column(property.name)}"

    if ranged
      relation = relation.where("#{quoted_foreign_key} >= $start")
      relation = relation.where("#{quoted_foreign_key} <= $end")
    end

    relation = relation.order("#{quoted_foreign_key} ASC") if type.nil?

    relation.to_sql
  end

  private

  attr_reader :property, :source, :type

  def base_association
    reflections.first
  end

  def column
    @column ||= property.columns.first
  end

  def reflections
    @reflections ||= begin
      base = source.model

      column.__stack.collect { |key|
        reflection = base.reflections[key]
        base       = reflection.klass

        extend_reflection reflection
      }.flatten
    end
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

  def offset
    "* #{ThinkingSphinx::Configuration.instance.indices.count} + #{source.offset}"
  end

  def quoted_foreign_key
    quote_with_table base_association.klass.table_name,
      base_association.foreign_key
  end

  def quoted_primary_key
    quote_with_table reflections.last.klass.table_name, column.__name
  end

  def quote_with_table(table, column)
    "#{quote_column(table)}.#{quote_column(column)}"
  end

  def quote_column(column)
    ActiveRecord::Base.connection.quote_column_name(column)
  end

  def extend_reflection(reflection)
    return [reflection] unless reflection.through_reflection

    [reflection.through_reflection, reflection.source_reflection]
  end
end
