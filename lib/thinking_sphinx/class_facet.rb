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
      # ThinkingSphinx.indexed_models.each do |i|
      #   return i if i.to_crc32 == attribute_value
      # end
      # 
      # raise "Unknown class crc"
    end
  end
end