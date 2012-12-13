module ThinkingSphinx::ActiveRecord::Base
  extend ActiveSupport::Concern

  included do
    after_destroy ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks
    before_save   ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
    after_update  ThinkingSphinx::ActiveRecord::Callbacks::UpdateCallbacks
    after_commit  ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks

    after_save    ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks

    ::ActiveRecord::Associations::CollectionProxy.send :include,
      ThinkingSphinx::ActiveRecord::AssociationProxy
  end

  module ClassMethods
    def facets(query = nil, options = {})
      search = ThinkingSphinx.facets query, options
      ThinkingSphinx::Search::Merger.new(search).merge! nil, :classes => [self]
    end

    def search(query = nil, options = {})
      merger = ThinkingSphinx::Search::Merger.new ThinkingSphinx.search

      merger.merge! *default_sphinx_scope_response if default_sphinx_scope?
      merger.merge! query, options
      merger.merge! nil, :classes => [self]
    end

    def search_count(query = nil, options = {})
      search(query, options).total_entries
    end

    def search_for_ids(query = nil, options = {})
      search = search query, options
      ThinkingSphinx::Search::Merger.new(search).merge! nil, :ids_only => true
    end

    private

    def default_sphinx_scope?
      respond_to?(:default_sphinx_scope) && default_sphinx_scope
    end

    def default_sphinx_scope_response
      [sphinx_scopes[default_sphinx_scope].call].flatten
    end
  end
end
