class ThinkingSphinx::Search::StaleIdsException < StandardError
  attr_reader :ids

  def initialize(ids)
    @ids = ids
  end

  def message
    "Record IDs found by Sphinx but not by ActiveRecord : #{ids.join(', ')}"
  end
end
