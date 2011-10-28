module ThinkingSphinx::ActiveRecord::Base
  extend ActiveSupport::Concern

  included do
    after_destroy ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks
    before_save   ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
    after_commit  ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
  end

  module ClassMethods
    def search(query = nil, options = {})
      ThinkingSphinx.search query, scoped_sphinx_options.merge(options)
    end

    def search_count(query = nil, options = {})
      search(query, options).total_entries
    end

    private

    def scoped_sphinx_options
      {:classes => [self]}
    end
  end
end
