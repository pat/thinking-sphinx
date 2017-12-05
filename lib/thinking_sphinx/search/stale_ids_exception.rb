# frozen_string_literal: true

class ThinkingSphinx::Search::StaleIdsException < StandardError
  attr_reader :ids, :context

  def initialize(ids, context)
    @ids = ids
    @context = context
  end

  def message
    "Record IDs found by Sphinx but not by ActiveRecord : #{ids.join(', ')}"
  end
end
