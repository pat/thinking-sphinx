# frozen_string_literal: true

class ThinkingSphinx::Deltas::DefaultDelta
  attr_reader :adapter, :options

  def initialize(adapter, options = {})
    @adapter, @options = adapter, options
  end

  def clause(delta_source = false)
    return nil unless delta_source

    "#{adapter.quoted_table_name}.#{quoted_column} = #{adapter.boolean_value delta_source}"
  end

  def delete(index, instance)
    ThinkingSphinx::Deltas::DeleteJob.new(
      index.name, index.document_id_for_instance(instance)
    ).perform
  end

  def index(index)
    ThinkingSphinx::Deltas::IndexJob.new(index.name).perform
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
