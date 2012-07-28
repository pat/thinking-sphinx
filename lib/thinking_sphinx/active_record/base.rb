module ThinkingSphinx::ActiveRecord::Base
  extend ActiveSupport::Concern

  included do
    after_destroy ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks
    before_save   ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
    after_commit  ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks

    after_save    ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks

    ::ActiveRecord::Associations::CollectionProxy.send :include,
      ThinkingSphinx::ActiveRecord::AssociationProxy
  end

  module ClassMethods
    def search(query = nil, options = {})
      search = ThinkingSphinx.search query, options
      search.options[:classes] = [self]
      search
    end

    def search_count(query = nil, options = {})
      search(query, options).total_entries
    end

    def search_for_ids(query = nil, options = {})
      search = search query, options
      search.options[:ids_only] = true
      search
    end
  end
end
