class ThinkingSphinx::Deltas::DefaultDelta
  attr_reader :adapter, :options

  def initialize(adapter, options = {})
    @adapter, @options = adapter, options
  end

  def clause(delta_source = false)
    "#{adapter.quoted_table_name}.#{quoted_column} = #{adapter.boolean_value delta_source}"
  end

  def delete(index, instance)
    config.connection.query Riddle::Query.update(
      index.name, index.document_id_for_key(instance.id),
      :sphinx_deleted => true
    )
  rescue Mysql2::Error => error
    # This isn't vital, so don't raise the error.
  end

  def index(index)
    controller.index index.name, :verbose => !config.settings['quiet_deltas']
  end

  def reset_query
    (<<-SQL).strip.gsub(/\n\s*/, ' ')
UPDATE #{adapter.quoted_table_name}
SET #{quoted_column} = #{adapter.boolean_value false}
WHERE #{quoted_column} = #{adapter.boolean_value true}
    SQL
  end

  def toggle(instance)
    instance.send "#{column}=", true
  end

  def toggled?(instance)
    instance.send "#{column}?"
  end

  private

  def column
    options[:column] || :delta
  end

  def config
    ThinkingSphinx::Configuration.instance
  end

  def controller
    config.controller
  end

  def quoted_column
    adapter.quote column
  end
end
