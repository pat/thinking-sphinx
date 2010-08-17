module ThinkingSphinx
  class FacetSearch < Hash
    attr_accessor :args, :options
    
    def initialize(*args)
      ThinkingSphinx.context.define_indexes
      
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
      client = config.client
      
      searches.each do |search|
        search.append_to client
      end
      
      client.run.each_with_index do |results, index|
        searches[index].populate_from_queue results
        add_from_results facet_names[index], searches[index]
      end
    end
    
    def searches
      @searches ||= facet_names.collect { |name|
        ThinkingSphinx.search *(args + [facet_search_options(name)])
      }
    end
    
    def facet_search_options(facet_name)
      options.merge(
        :group_function => :attr,
        :limit          => max_matches,
        :max_matches    => max_matches,
        :page           => 1,
        :group_by       => facet_name,
        :ids_only       => !translate?(facet_name)
      )
    end
    
    def facet_classes
      (
        options[:classes] || ThinkingSphinx.context.indexed_models.collect { |model|
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
    
    def translate?(name)
      facet = facet_from_name(name)
      facet.translate? || facet.float?
    end
    
    def config
      ThinkingSphinx::Configuration.instance
    end
    
    def max_matches
      @max_matches ||= config.configuration.searchd.max_matches || 1000
    end
    
    # example: facet = country_facet; name = :country
    def add_from_results(facet, search)
      name  = ThinkingSphinx::Facet.name_for(facet)
      facet = facet_from_name(facet)
      
      self[name]  ||= {}
      
      return if search.empty?
      
      search.each_with_match do |result, match|
        facet_value = facet.value(result, match[:attributes])
        
        self[name][facet_value] ||= 0
        self[name][facet_value]  += match[:attributes]["@count"]
      end
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
      facet = nil
      klass = object.class
      
      while klass != ::ActiveRecord::Base && facet.nil?
        facet = klass.sphinx_facets.detect { |facet|
          facet.attribute_name == name
        }
        klass = klass.superclass
      end
      
      facet
    end
    
    def facet_from_name(name)
      name = ThinkingSphinx::Facet.name_for(name)
      all_facets.detect { |facet|
        facet.name == name
      }
    end
  end
end
