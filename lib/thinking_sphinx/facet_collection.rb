module ThinkingSphinx
  class FacetCollection < Hash
    attr_accessor :arguments
    
    def initialize(arguments)
      @arguments        = arguments.clone
      @attribute_values = {}
      @facets           = []
    end
    
    def add_from_results(facet, results)
      self[facet.name]          ||= {}
      @attribute_values[facet.name] ||= {}
      @facets << facet
      
      results.each_with_groupby_and_count { |result, group, count|
        facet_value = facet.value(result, group)
        
        self[facet.name][facet_value]              = 0
        self[facet.name][facet_value]              = count
        @attribute_values[facet.name][facet_value] = group
      }
    end
    
    def for(hash = {})
      arguments        = @arguments.clone
      options          = arguments.extract_options!
      options[:with] ||= {}
      
      hash.each do |key, value|
        attrib = facet_for_key(key).attribute_name
        options[:with][attrib] = @attribute_values[key][value]
      end
      
      arguments << options
      ThinkingSphinx::Search.search *arguments
    end
    
    private
    
    def facet_for_key(key)
      @facets.detect { |facet| facet.name == key }
    end
  end
end