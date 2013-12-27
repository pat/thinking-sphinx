module ThinkingSphinx::Query
  def self.escape(query)
    Riddle::Query.escape query
  end

  def self.wildcard(query, pattern = true)
    ThinkingSphinx::Wildcard.call query, pattern
  end
end
