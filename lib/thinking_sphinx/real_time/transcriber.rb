# frozen_string_literal: true

class ThinkingSphinx::RealTime::Transcriber
  def initialize(index)
    @index = index
  end

  def clear_before(time)
    execute <<~SQL.strip
      DELETE FROM #{@index.name} WHERE sphinx_updated_at < #{time.to_i}
    SQL
  end

  def copy(*instances)
    items = instances.select { |instance|
      instance.persisted? && copy?(instance)
    }
    return unless items.present?

    delete_existing items
    insert_replacements items
  end

  private

  attr_reader :index

  def columns
    @columns ||= properties.each_with_object(['id']) do |property, columns|
      columns << property.name
    end
  end

  def copy?(instance)
    index.conditions.empty? || index.conditions.all? { |condition|
      case condition
      when Symbol
        instance.send(condition)
      when Proc
        condition.call instance
      else
        "Unexpected condition: #{condition}. Expecting Symbol or Proc."
      end
    }
  end

  def delete_existing(instances)
    ids = instances.collect(&index.primary_key.to_sym)

    execute <<~SQL.strip
      DELETE FROM #{@index.name} WHERE sphinx_internal_id IN (#{ids.join(', ')})
    SQL
  end

  def execute(sphinxql)
    ThinkingSphinx::Logger.log :query, sphinxql do
      ThinkingSphinx::Connection.take do |connection|
        connection.execute sphinxql
      end
    end
  end

  def insert_replacements(instances)
    insert = Riddle::Query::Insert.new index.name, columns, values(instances)
    execute insert.replace!.to_sql
  end

  def instrument(message, options = {})
    ActiveSupport::Notifications.instrument(
      "#{message}.thinking_sphinx.real_time", options.merge(:index => index)
    )
  end

  def properties
    @properties ||= index.fields + index.attributes
  end

  def values(instances)
    instances.each_with_object([]) do |instance, array|
      begin
        array << ThinkingSphinx::RealTime::TranscribeInstance.call(
          instance, index, properties
        )
      rescue ThinkingSphinx::TranscriptionError => error
        instrument 'error', :error => error
      end
    end
  end
end
