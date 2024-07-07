# frozen_string_literal: true

module ThinkingSphinx::ActiveRecord::Base
  extend ActiveSupport::Concern

  included do
    # Avoid method collisions for public Thinking Sphinx methods added to all
    # ActiveRecord models. The `sphinx_`-prefixed versions will always exist,
    # and the non-prefixed versions will be added if a method of that name
    # doesn't already exist.
    #
    # If a method is overwritten later by something else, that's also fine - the
    # prefixed versions will still be there.
    class_module = ThinkingSphinx::ActiveRecord::Base::ClassMethods
    class_module.public_instance_methods.each do |method_name|
      short_method = method_name.to_s.delete_prefix("sphinx_").to_sym
      next if methods.include?(short_method)

      define_singleton_method(short_method, method(method_name))
    end

    if ActiveRecord::VERSION::STRING.to_i >= 5
      [
        ::ActiveRecord::Reflection::HasManyReflection,
        ::ActiveRecord::Reflection::HasAndBelongsToManyReflection
      ].each do |reflection_class|
        reflection_class.include DefaultReflectionAssociations
      end
    else
      ::ActiveRecord::Associations::CollectionProxy.include(
        ThinkingSphinx::ActiveRecord::AssociationProxy
      )
    end
  end

  module DefaultReflectionAssociations
    def extensions
      super + [ThinkingSphinx::ActiveRecord::AssociationProxy]
    end
  end

  module ClassMethods
    def sphinx_facets(query = nil, options = {})
      merge_search ThinkingSphinx.facets, query, options
    end

    def sphinx_search(query = nil, options = {})
      merge_search ThinkingSphinx.search, query, options
    end

    def sphinx_search_count(query = nil, options = {})
      search_for_ids(query, options).total_entries
    end

    def sphinx_search_for_ids(query = nil, options = {})
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
