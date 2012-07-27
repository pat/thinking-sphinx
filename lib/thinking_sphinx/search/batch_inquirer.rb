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

      results  = [connection.query(@queries.join('; '))]
      results << connection.store_result while connection.next_result
      results
    end
  end

  private

  def connection
    @connection ||= ThinkingSphinx::Configuration.instance.connection
  end
end
