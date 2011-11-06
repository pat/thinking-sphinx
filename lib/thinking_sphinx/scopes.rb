module ThinkingSphinx::Scopes
  extend ActiveSupport::Concern

  module ClassMethods
    def sphinx_scope(name, &block)
      sphinx_scopes[name] = block
    end

    def sphinx_scopes
      @sphinx_scopes ||= {}
    end

    private

    def method_missing(method, *args, &block)
      return super unless sphinx_scopes.keys.include?(method)

      query, options = sphinx_scopes[method].call(*args)
      search query, (options || {})
    end
  end
end
