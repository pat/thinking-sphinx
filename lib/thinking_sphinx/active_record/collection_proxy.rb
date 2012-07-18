module ThinkingSphinx
  module ActiveRecord
    module CollectionProxy
      def search(*args)
        proxy_association.klass.search(*association_args(args))
      end

      def facets(*args)
        proxy_association.klass.facets(*association_args(args))
      end

      private

      def association_args(args)
        options = args.extract_options!
        options[:with] ||= {}
        options[:with].merge! default_filter

        args + [options]
      end

      def attribute_for_foreign_key
        if proxy_association.reflection.through_reflection
          foreign_key = proxy_association.reflection.through_reflection.foreign_key
        else
          foreign_key = proxy_association.reflection.foreign_key
        end

        proxy_association.klass.define_indexes
        (proxy_association.klass.sphinx_indexes || []).each do |index|
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
        {attribute_for_foreign_key.unique_name => proxy_association.owner.id}
      end
    end
  end
end
