class ThinkingSphinx::RealTime::Transcriber
  def initialize(index)
    @index = index
  end

  def copy(instance)
    return unless instance.persisted? && copy?(instance)

    columns, values = ['id'], [index.document_id_for_key(instance.id)]
    (index.fields + index.attributes).each do |property|
      columns << property.name
      values  << property.translate(instance)
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
