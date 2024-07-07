# frozen_string_literal: true

class ThinkingSphinx::Masks::ScopesMask
  def initialize(search)
    @search = search
  end

  def can_handle?(method)
    public_methods(false).include?(method) || can_apply_scope?(method)
  end

  def facets(query = nil, options = {})
    search = ThinkingSphinx.facets query, options
    ThinkingSphinx::Search::Merger.new(search).merge!(
      @search.query, @search.options
    )
  end

  def search(query = nil, options = {})
    query, options = nil, query if query.is_a?(Hash)
    ThinkingSphinx::Search::Merger.new(@search).merge! query, options
  end

  def search_for_ids(query = nil, options = {})
    query, options = nil, query if query.is_a?(Hash)
    search query, options.merge(:ids_only => true)
  end

  def none
    ThinkingSphinx::Search::Merger.new(@search).merge! nil, :none => true
  end

  alias_method :search_none, :none

  private

  def apply_scope(scope, *args)
    query, options = sphinx_scopes[scope].call(*args)
    search query, options
  end

  def can_apply_scope?(scope)
    @search.options[:classes].present?    &&
    @search.options[:classes].length == 1 &&
    @search.options[:classes].first.respond_to?(:sphinx_scopes) &&
    sphinx_scopes[scope].present?
  end

  def method_missing(method, *args, &block)
    apply_scope method, *args
  end

  def sphinx_scopes
    @search.options[:classes].first.sphinx_scopes
  end
end
