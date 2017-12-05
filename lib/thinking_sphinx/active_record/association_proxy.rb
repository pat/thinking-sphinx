# frozen_string_literal: true

module ThinkingSphinx::ActiveRecord::AssociationProxy
  extend ActiveSupport::Concern

  def search(query = nil, options = {})
    perform_search super(*normalise_search_arguments(query, options))
  end

  def search_for_ids(query = nil, options = {})
    perform_search super(*normalise_search_arguments(query, options))
  end

  private
  def normalise_search_arguments(query, options)
    query, options = nil, query if query.is_a?(Hash)
    options[:ignore_scopes] = true

    [query, options]
  end

  def perform_search(searcher)
    ThinkingSphinx::Search::Merger.new(searcher).merge! nil,
      :with => association_filter
  end

  def association_filter
    attribute = AttributeFinder.new(proxy_association).attribute

    {attribute.name.to_sym => proxy_association.owner.id}
  end
end

require 'thinking_sphinx/active_record/association_proxy/attribute_finder'
require 'thinking_sphinx/active_record/association_proxy/attribute_matcher'
