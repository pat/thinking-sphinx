module ThinkingSphinx
  module ActiveRecord
    module HasManyAssociation
      def search(*args)
        @reflection.klass.search(*association_args(args))
      end

      def facets(*args)
        @reflection.klass.facets(*association_args(args))
      end

      private

      def association_args(args)
        options = args.extract_options!
        options[:with] ||= {}
        options[:with].merge! default_filter

        args + [options]
      end

      def attribute_for_foreign_key
        foreign_key = @reflection.primary_key_name
        stack = [@reflection.options[:through]].compact
        
        @reflection.klass.define_indexes
        (@reflection.klass.sphinx_indexes || []).each do |index|
          attribute = index.attributes.detect { |attrib|
            attrib.columns.length == 1 &&
            attrib.columns.first.__name  == foreign_key.to_sym ||
            attrib.alias == foreign_key.to_sym
          }
          return attribute unless attribute.nil?
        end
        
        raise "Missing Attribute for Foreign Key #{foreign_key}"
      end
      
      def default_filter
        {attribute_for_foreign_key.unique_name => @owner.id}
      end
    end
  end
end
