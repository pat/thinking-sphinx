module ThinkingSphinx
  module ActiveRecord
    module CollectionProxyWithScopes
      def self.included(base)
        base.class_eval do
          alias_method_chain :method_missing, :sphinx_scopes
        end
      end

      def method_missing_with_sphinx_scopes(method, *args, &block)
        if responds_to_scope(method)
          proxy_association.klass.
            search(:with => default_filter).
            send(method, *args, &block)
        else
          method_missing_without_sphinx_scopes(method, *args, &block)
        end
      end

      private
      def responds_to_scope(scope)
        proxy_association.klass.respond_to?(:sphinx_scopes) &&
        proxy_association.klass.sphinx_scopes.include?(scope)
      end
    end
  end
end
