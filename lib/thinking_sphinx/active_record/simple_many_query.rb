class ThinkingSphinx::ActiveRecord::SimpleManyQuery <
  ThinkingSphinx::ActiveRecord::PropertyQuery

  def to_s
    "#{identifier} from #{source_type}; #{queries.join('; ')}"
  end

  private

  def reflection
    @reflection ||= source.model.reflect_on_association column.__stack.first
  end

  def quoted_foreign_key
    quote_with_table reflection.join_table, reflection.foreign_key
  end

  def quoted_primary_key
    quote_with_table reflection.join_table, reflection.association_foreign_key
  end

  def range_sql
    "SELECT MIN(#{quoted_foreign_key}), MAX(#{quoted_foreign_key}) FROM #{quote_column reflection.join_table}"
  end

  def to_sql
    selects = [
      "#{quoted_foreign_key} #{offset} AS #{quote_column('id')}",
      "#{quoted_primary_key} AS #{quote_column(property.name)}"
    ]
    sql  = "SELECT #{selects.join(', ')} FROM #{quote_column reflection.join_table}"
    sql += " WHERE (#{quoted_foreign_key} BETWEEN $start AND $end)" if ranged?
    sql
  end
end
