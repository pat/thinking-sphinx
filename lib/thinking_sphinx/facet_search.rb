module ThinkingSphinx
  class FacetSearch < Hash
    attr_accessor :args, :options
    
    def initialize(*args)
      @options      = args.extract_options!
      @args         = args
      
      set_default_options
      
      populate
    end
    
    def for(hash = {})
      for_options = {:with => {}}.merge(options)
      
      hash.each do |key, value|
        attrib = ThinkingSphinx::Facet.attribute_name_from_value(key, value)
        for_options[:with][attrib] = underlying_value key, value
      end
      
      ThinkingSphinx.search *(args + [for_options])
    end
    
    def facet_names
      @facet_names ||= begin
        names = options[:all_facets] ?
          facet_names_for_all_classes : facet_names_common_to_all_classes
        
        names.delete "class_crc" unless options[:class_facet]
        names
      end
    end
    
    private
    
    def set_default_options
      options[:all_facets]  ||= false
      if options[:class_facet].nil?
        options[:class_facet] = ((options[:classes] || []).length != 1)
      end
    end
    
    def populate
      facet_names.each do |name|
        search_options = facet_search_options.merge(:group_by => name)
        add_from_results name, ThinkingSphinx.search(
          *(args + [search_options])
        )
      end
    end
    
    def facet_search_options
      config = ThinkingSphinx::Configuration.instance
      max    = config.configuration.searchd.max_matches || 1000
      
      options.merge(
        :group_function => :attr,
        :limit          => max,
        :max_matches    => max,
        :page           => 1
      )
    end
    
    def facet_classes
      (
        options[:classes] || ThinkingSphinx.indexed_models.collect { |model|
          model.constantize
        }
      ).select { |klass| klass.sphinx_facets.any? }
    end
    
    def all_facets
      facet_classes.collect { |klass|
        klass.sphinx_facets
      }.flatten.select { |facet|
        options[:facets].blank? || Array(options[:facets]).include?(facet.name)
      }
    end
    
    def facet_names_for_all_classes
      all_facets.group_by { |facet|
        facet.name
      }.collect { |name, facets|
        if facets.collect { |facet| facet.type }.uniq.length > 1
          raise "Facet #{name} exists in more than one model with different types"
        end
        facets.first.attribute_name
      }
    end
    
    def facet_names_common_to_all_classes
      facet_names_for_all_classes.select { |name|
        facet_classes.all? { |klass|
          klass.sphinx_facets.detect { |facet|
            facet.attribute_name == name
          }
        }
      }
    end
    
    def add_from_results(facet, results)
      name = ThinkingSphinx::Facet.name_for(facet)
      
      self[name]  ||= {}
      
      return if results.empty?
      
      facet = facet_from_object(results.first, facet) if facet.is_a?(String)
      
      results.each_with_groupby_and_count { |result, group, count|
        facet_value = facet.value(result, group)
        
        self[name][facet_value] ||= 0
        self[name][facet_value]  += count
      }
    end
    
    def underlying_value(key, value)
      case value
      when Array
        value.collect { |item| underlying_value(key, item) }
      when String
        value.to_crc32
      else
        value
      end
    end
    
    def facet_from_object(object, name)
      object.sphinx_facets.detect { |facet| facet.attribute_name == name }
    end
  end
end
