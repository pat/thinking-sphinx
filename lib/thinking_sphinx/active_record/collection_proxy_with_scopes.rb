module ThinkingSphinx
  module ActiveRecord
    module CollectionProxyWithScopes
      def self.included(base)
        base.class_eval do
          alias_method_chain :method_missing, :sphinx_scopes
          alias_method_chain :respond_to?, :sphinx_scopes
        end
      end

      def method_missing_with_sphinx_scopes(method, *args, &block)
        klass = proxy_association.klass
        if klass.respond_to?(:sphinx_scopes) && klass.sphinx_scopes.include?(method)
          klass.search(:with => default_filter).send(method, *args, &block)
        else
          method_missing_without_sphinx_scopes(method, *args, &block)
        end
      end

      def respond_to_with_sphinx_scopes?(method)
        proxy_association.klass.respond_to?(:sphinx_scopes) &&
        proxy_association.klass.sphinx_scopes.include?(scope) ||
        respond_to_without_sphinx_scopes?(method)
      end
    end
  end
end
