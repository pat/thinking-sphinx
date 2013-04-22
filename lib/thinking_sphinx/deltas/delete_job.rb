class ThinkingSphinx::Deltas::DeleteJob
  def initialize(indices, document_id)
    @indices, @document_id = indices, document_id
  end

  def perform
    ThinkingSphinx::Connection.take do |client|
      @indices.each do |index|
        client.update(index, ['sphinx_deleted'], {@document_id => [1]})
      end
    end
  rescue Riddle::ConnectionError, Riddle::ResponseError,
    ThinkingSphinx::SphinxError, Errno::ETIMEDOUT, Timeout::Error
    # Not the end of the world if Sphinx isn't running.
  end
end
