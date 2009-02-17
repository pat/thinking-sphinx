module ThinkingSphinx
  class ClassFacet < ThinkingSphinx::Facet
    def name
      :class
    end
    
    def attribute_name
      "class_crc"
    end
    
    def value(object, attribute_value)
      object.class.name
    end
  end
end
