module ThinkingSphinx::ActiveRecord::Base
  extend ActiveSupport::Concern

  included do
    before_save  ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
    after_commit ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
  end

  module ClassMethods
    def search(query = nil, options = {})
      ThinkingSphinx.search query, scoped_sphinx_options.merge(options)
    end

    def primary_key_for_sphinx
      @primary_key_for_sphinx ||
      (
        superclass.respond_to?(:primary_key_for_sphinx?) &&
        superclass.primary_key_for_sphinx? &&
        superclass.primary_key_for_sphinx
      ) || primary_key || :id
    end

    def primary_key_for_sphinx?
      @primary_key_for_sphinx.present?
    end

    def set_primary_key_for_sphinx(key)
      @primary_key_for_sphinx = key
    end

    private

    def scoped_sphinx_options
      {:classes => [self]}
    end
  end
end
