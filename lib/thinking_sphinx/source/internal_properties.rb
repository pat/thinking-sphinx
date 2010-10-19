module ThinkingSphinx
  class Source
    module InternalProperties
      def add_internal_attributes_and_facets
        add_internal_attribute :sphinx_internal_id, nil,
          @model.primary_key_for_sphinx.to_sym
        add_internal_attribute :class_crc,          :integer, crc_column, true
        add_internal_attribute :sphinx_deleted,     :integer, "0"

        add_internal_facet :class_crc
      end

      def add_internal_attribute(name, type, contents, facet = false)
        return unless attribute_by_alias(name).nil?

        Attribute.new(self,
          ThinkingSphinx::Index::FauxColumn.new(contents),
          :type   => type,
          :as     => name,
          :facet  => facet,
          :admin  => true
        )
      end

      def add_internal_facet(name)
        return unless facet_by_alias(name).nil?

        @model.sphinx_facets << ClassFacet.new(attribute_by_alias(name))
      end

      def attribute_by_alias(attr_alias)
        @attributes.detect { |attrib| attrib.alias == attr_alias }
      end

      def facet_by_alias(name)
        @model.sphinx_facets.detect { |facet| facet.name == name }
      end

      def subclasses_to_s
        "'" + (@model.send(:descendants).collect { |klass|
          klass.to_crc32.to_s
        } << @model.to_crc32.to_s).join(",") + "'"
      end
    end
  end
end