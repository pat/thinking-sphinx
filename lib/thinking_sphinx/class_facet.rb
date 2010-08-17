module ThinkingSphinx
  class ClassFacet < ThinkingSphinx::Facet
    def name
      :class
    end
    
    def attribute_name
      "class_crc"
    end
    
    def value(object, attribute_hash)
      crc = attribute_hash['class_crc']
      ThinkingSphinx::Configuration.instance.models_by_crc[crc]
    end
  end
end
