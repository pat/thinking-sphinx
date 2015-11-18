class ThinkingSphinx::RealTime::Transcriber
  def initialize(index)
    @index = index
  end

  def copy(*instances)
    items = instances.flatten.select { |instance| instance.persisted? && copy?(instance) }
    return unless items.present?
    properties = (index.fields + index.attributes)
    values = []
    columns = properties.each_with_object(['id']) do |property, columns|
      columns << property.name
    end
    items.each do |instance|
      values << properties.each_with_object([index.document_id_for_key(instance.id)]) do |property, instance_values|
        instance_values << property.translate(instance)
      end
    end

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
end
