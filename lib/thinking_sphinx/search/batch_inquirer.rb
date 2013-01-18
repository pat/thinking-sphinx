class ThinkingSphinx::Search::BatchInquirer
  def initialize(&block)
    @queries = []

    yield self if block_given?
  end

  def append_query(query)
    @queries << query
  end

  def results
    @results ||= begin
      @queries.freeze

      ThinkingSphinx::Connection.take do |connection|
        connection.query_all *@queries
      end
    end
  end
end
