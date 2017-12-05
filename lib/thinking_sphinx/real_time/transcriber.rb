class ThinkingSphinx::RealTime::Transcriber
  def initialize(index)
    @index = index
  end

  def copy(*instances)
    items = instances.select { |instance|
      instance.persisted? && copy?(instance)
    }
    return unless items.present?

    values = items.collect { |instance|
      ThinkingSphinx::RealTime::TranscribeInstance.call(instance, index, properties)
    }

    insert = Riddle::Query::Insert.new index.name, columns, values
    sphinxql = insert.replace!.to_sql

    ThinkingSphinx::Logger.log :query, sphinxql do
      ThinkingSphinx::Connection.take do |connection|
        connection.execute sphinxql
      end
    end
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

  def properties
    @properties ||= index.fields + index.attributes
  end
end
