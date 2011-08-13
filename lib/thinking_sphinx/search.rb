class ThinkingSphinx::Search < Array
  def initialize(query = nil)
  end

  def empty?
    populate
    super
  end

  private

  def connection
    @connection ||= Riddle::Query.connection
  end

  def populate
    replace connection.query.collect { |record|
      record
    }
  end
end
