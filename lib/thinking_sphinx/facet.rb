module ThinkingSphinx
  class Facet
    attr_reader :name, :column, :reference
    
    def initialize(name, columns, reference)
      @name = name
      @columns = columns
      @reference = reference
    end
    
    def attribute_name
      @attribute_name ||= case @reference
      when Attribute
        @reference.unique_name.to_s
      when Field
        @reference.unique_name.to_s + "_sort"
      end
    end
    
    def value(object, attribute_value)
      return translate(object, attribute_value) if @reference.is_a?(Field)
      
      case @reference.type
      when :string, :multi
        translate(object, attribute_value)
      when :datetime
        Time.at(attribute_value)
      when :boolean
        attribute_value > 0
      else
        attribute_value
      end
    end
    
    private
    
    def translate(object, attribute_value)
      if @columns.length > 1
        raise "Can't translate Facets on multiple-column field or attribute"
      end
      
      column  = @columns.first
      column.__stack.each { |method|
        object = object.send(method)
      }
      object.send(column.__name)
    end
  end
end