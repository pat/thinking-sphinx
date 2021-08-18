# frozen_string_literal: true

class ThinkingSphinx::Search::StaleIdsException < StandardError
  attr_reader :ids, :context

  def initialize(ids, context)
    @ids = ids
    @context = context
  end

  def message
    "Record IDs found by Sphinx but not by ActiveRecord : #{ids.join(', ')}\n" \
    "https://freelancing-gods.com/thinking-sphinx/v5/common_issues.html#record-ids"
  end
end
