module ThinkingSphinx::ActiveRecord::Base
  extend ActiveSupport::Concern

  included do
    after_destroy ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks
    before_save   ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
    after_update  ThinkingSphinx::ActiveRecord::Callbacks::UpdateCallbacks
    after_commit  ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks

    ::ActiveRecord::Associations::CollectionProxy.send :include,
      ThinkingSphinx::ActiveRecord::AssociationProxy
  end

  module ClassMethods
    def facets(query = nil, options = {})
      merge_search ThinkingSphinx.facets, query, options
    end

    def search(query = nil, options = {})
      merge_search ThinkingSphinx.search, query, options
    end

    def search_count(query = nil, options = {})
      search(query, options).total_entries
    end

    def search_for_ids(query = nil, options = {})
      ThinkingSphinx::Search::Merger.new(
        search(query, options)
      ).merge! nil, :ids_only => true
    end

    private

    def default_sphinx_scope?
      respond_to?(:default_sphinx_scope) && default_sphinx_scope
    end

    def default_sphinx_scope_response
      [sphinx_scopes[default_sphinx_scope].call].flatten
    end

    def merge_search(search, query, options)
      merger = ThinkingSphinx::Search::Merger.new search

      merger.merge! *default_sphinx_scope_response if default_sphinx_scope?
      merger.merge! query, options

      if current_scope && !merger.search.options[:ignore_scopes]
        raise ThinkingSphinx::MixedScopesError,
          'You cannot search with Sphinx through ActiveRecord scopes'
      end

      result = merger.merge! nil, :classes => [self]
      result.populate if result.options[:populate]
      result
    end
  end
end
