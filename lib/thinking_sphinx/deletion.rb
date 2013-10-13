class ThinkingSphinx::Deletion
  delegate :name, :to => :index

  def self.perform(index, instance)
    {
      'plain' => PlainDeletion,
      'rt'    => RealtimeDeletion
    }[index.type].new(index, instance).perform
  rescue ThinkingSphinx::ConnectionError => error
    # This isn't vital, so don't raise the error.
  end

  def initialize(index, instance)
    @index, @instance = index, instance
  end

  private

  attr_reader :index, :instance

  def document_id_for_key
    index.document_id_for_key instance.id
  end

  def execute(statement)
    ThinkingSphinx::Connection.take do |connection|
      connection.execute statement
    end
  end

  class RealtimeDeletion < ThinkingSphinx::Deletion
    def perform
      execute Riddle::Query::Delete.new(name, document_id_for_key).to_sql
    end
  end

  class PlainDeletion < ThinkingSphinx::Deletion
    def perform
      execute Riddle::Query.update(
        name, document_id_for_key, :sphinx_deleted => true
      )
    end
  end
end
