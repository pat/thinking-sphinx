class ThinkingSphinx::Deltas::DeleteJob
  def initialize(index_name, document_id)
    @index_name, @document_id = index_name, document_id
  end

  def perform
    ThinkingSphinx::Connection.take do |connection|
      connection.execute Riddle::Query.update(
        @index_name, @document_id, :sphinx_deleted => true
      )
    end
  rescue ThinkingSphinx::ConnectionError => error
    # This isn't vital, so don't raise the error.
  end
end
