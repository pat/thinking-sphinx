module ThinkingSphinx
  class Facet
    attr_reader :reference
    
    def initialize(reference)
      @reference = reference
      
      if reference.columns.length != 1
        raise "Can't translate Facets on multiple-column field or attribute"
      end
    end

    def self.name_for(facet)
      case facet
      when Facet
        facet.name
      when String, Symbol
        facet.to_s.gsub(/_facet$/,'').to_sym
      end
    end
    
    def name
      reference.unique_name
    end

    def self.attribute_name_for(name)
      name.to_s + '_facet'
    end
    
    def attribute_name
      # @attribute_name ||= case @reference
      # when Attribute
      #   @reference.unique_name.to_s
      # when Field
      @attribute_name ||= @reference.unique_name.to_s + "_facet"
      # end
    end
    
    def value(object, attribute_value)
      return translate(object, attribute_value) if @reference.is_a?(Field)
      
      case @reference.type
      when :string
        translate(object, attribute_value)
      when :datetime
        Time.at(attribute_value)
      when :boolean
        attribute_value > 0
      else
        attribute_value
      end
    end
    
    def to_s
      name
    end
    
    private
    
    def translate(object, attribute_value)
      column.__stack.each { |method|
        object = object.send(method)
      }
      object.send(column.__name)
    end
    
    def column
      @reference.columns.first
    end
  end
end
