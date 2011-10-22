class ThinkingSphinx::Deltas::DefaultDelta
  attr_reader :adapter

  def initialize(adapter)
    @adapter = adapter
  end

  def clause(delta_source = false)
    "#{adapter.quoted_table_name}.#{delta_column} = #{adapter.boolean_value delta_source}"
  end

  def reset_query
    (<<-SQL).strip.gsub(/\n\s*/, ' ')
UPDATE #{adapter.quoted_table_name}
SET #{delta_column} = #{adapter.boolean_value false}
WHERE #{delta_column} = #{adapter.boolean_value true}
    SQL
  end

  private

  def delta_column
    adapter.quote :delta
  end
end
