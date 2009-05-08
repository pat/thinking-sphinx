module ThinkingSphinx
  class FacetCollection < Hash
    attr_accessor :arguments
    
    def initialize(arguments)
      @arguments        = arguments.clone
      @attribute_values = {}
      @facet_names           = []
    end
    
    def add_from_results(facet, results)
      name = ThinkingSphinx::Facet.name_for(facet)

      self[name]              ||= {}
      @attribute_values[name] ||= {}
      @facet_names << name

      return if results.empty?

      facet = facet_from_object(results.first, facet) if facet.is_a?(String)
      
      results.each_with_groupby_and_count { |result, group, count|
        facet_value = facet.value(result, group)
        
        self[name][facet_value]              ||= 0
        self[name][facet_value]              += count
        @attribute_values[name][facet_value]  = group
      }
    end
    
    def for(hash = {})
      arguments        = @arguments.clone
      options          = arguments.extract_options!
      options[:with] ||= {}
      
      hash.each do |key, value|
        attrib = ThinkingSphinx::Facet.attribute_name_for(key)
        options[:with][attrib] = underlying_value key, value
      end
      
      arguments << options
      ThinkingSphinx::Search.search *arguments
    end
    
    private
    
    def underlying_value(key, value)
      case value
      when Array
        value.collect { |item| underlying_value(key, item) }
      else
        @attribute_values[key][value]
      end
    end
    
    def facet_from_object(object, name)
      object.sphinx_facets.detect { |facet| facet.attribute_name == name }
    end
  end
end
