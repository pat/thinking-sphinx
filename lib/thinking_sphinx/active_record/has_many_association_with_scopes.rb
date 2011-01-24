module ThinkingSphinx
  module ActiveRecord
    module HasManyAssociationWithScopes
      def method_missing(method, *args, &block)
        if responds_to_scope(method)
          @reflection.klass.
            search(:with => default_filter).
            send(method, *args, &block)
        else
          super
        end
      end
      
      private
      def responds_to_scope(scope)
        @reflection.klass.respond_to?(:sphinx_scopes)   &&
        @reflection.klass.sphinx_scopes.include?(scope)
      end
    end
  end
end
