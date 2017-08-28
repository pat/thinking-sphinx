class ThinkingSphinx::Deltas::DeleteJob
  def initialize(index_name, document_id)
    @index_name, @document_id = index_name, document_id
  end

  def perform
    return if @document_id.nil?

    ThinkingSphinx::Logger.log :query, statement do
      ThinkingSphinx::Connection.take do |connection|
        connection.execute statement
      end
    end
  rescue ThinkingSphinx::ConnectionError => error
    # This isn't vital, so don't raise the error.
  end

  private

  def statement
    @statement ||= Riddle::Query.update(
      @index_name, @document_id, :sphinx_deleted => true
    )
  end
end
