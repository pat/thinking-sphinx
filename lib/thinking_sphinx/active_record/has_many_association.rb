module ThinkingSphinx
  module ActiveRecord
    module HasManyAssociation
      def search(*args)
        options   = args.extract_options!
        options[:with] ||= {}
        options[:with].merge! default_filter
        
        args << options
        @reflection.klass.search(*args)
      end
      
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
      
      def attribute_for_foreign_key
        foreign_key = @reflection.primary_key_name
        stack = [@reflection.options[:through]].compact
        
        @reflection.klass.define_indexes
        (@reflection.klass.sphinx_indexes || []).each do |index|
          attribute = index.attributes.detect { |attrib|
            attrib.columns.length == 1 &&
            attrib.columns.first.__name  == foreign_key.to_sym
          }
          return attribute unless attribute.nil?
        end
        
        raise "Missing Attribute for Foreign Key #{foreign_key}"
      end
      
      def default_filter
        {attribute_for_foreign_key.unique_name => @owner.id}
      end
      
      def responds_to_scope(scope)
        @reflection.klass.respond_to?(:sphinx_scopes)   &&
        @reflection.klass.sphinx_scopes.include?(scope)
      end
    end
  end
end
