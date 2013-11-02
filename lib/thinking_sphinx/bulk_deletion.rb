class ThinkingSphinx::BulkDeletion
  delegate :name, :to => :index

  def self.perform(index, ids)
    return if index.distributed?

    {
      'plain' => PlainDeletion,
      'rt'    => RealtimeDeletion
    }[index.type].new(index, ids).perform
  rescue ThinkingSphinx::ConnectionError => error
    # This isn't vital, so don't raise the error.
  end

  def initialize(index, ids)
    @index, @ids = index, ids
  end

  private

  attr_reader :index, :ids

  def document_ids_for_keys
    ids.collect { |id| index.document_id_for_key id }
  end

  def execute(statement)
    ThinkingSphinx::Connection.take do |connection|
      connection.execute statement
    end
  end

  class RealtimeDeletion < ThinkingSphinx::BulkDeletion
    def perform
      execute Riddle::Query::Delete.new(name, document_ids_for_keys).to_sql
    end
  end

  class PlainDeletion < ThinkingSphinx::BulkDeletion
    def perform
      execute <<-SQL
UPDATE #{name}
SET sphinx_deleted = 1
WHERE id IN (#{document_ids_for_keys.join(', ')})
      SQL
    end
  end
end
