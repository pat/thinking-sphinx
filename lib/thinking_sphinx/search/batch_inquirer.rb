class ThinkingSphinx::Search::BatchInquirer
  def initialize(&block)
    @queries = []

    yield self
  end

  def append_query(query)
    @queries << query
  end

  def results
    @results ||= begin
      @queries.freeze

      connection = ThinkingSphinx::Configuration.instance.connection
      results    = connection.query @queries.join('; ')

      (1..(@queries.length - 1)).collect {
        connection.store_result if connection.next_result
      }.unshift results
    end
  end
end
