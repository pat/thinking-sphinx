module ThinkingSphinx
  class ClassFacet < ThinkingSphinx::Facet
    def name
      :class
    end
    
    def attribute_name
      Riddle.loaded_version.to_i < 2 ? 'class_crc' : 'sphinx_internal_class'
    end
    
    def value(object, attribute_hash)
      if Riddle.loaded_version.to_i < 2
        crc = attribute_hash['class_crc']
        ThinkingSphinx::Configuration.instance.models_by_crc[crc]
      else
        attribute_hash['sphinx_internal_class']
      end
    end
  end
end
