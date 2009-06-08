module ThinkingSphinx
  class Search
    module Facets
      # Model.facets *args
      # ThinkingSphinx::Search.facets *args
      # ThinkingSphinx::Search.facets *args, :all_attributes  => true
      # ThinkingSphinx::Search.facets *args, :class_facet     => false
      # 
      def facets(*args)
        options = args.extract_options!
        
        if options[:class]
          facets_for_model options[:class], args, options
        else
          facets_for_all_models args, options
        end
      end
      
      private
      
      def facets_for_model(klass, args, options)
        hash    = ThinkingSphinx::FacetCollection.new args + [options]
        options = options.clone.merge! facet_query_options
        
        facets  = klass.sphinx_facets
        facets  = Array(options.delete(:facets)).collect { |name|
          klass.sphinx_facets.detect { |facet| facet.name.to_s == name.to_s }
        }.compact if options[:facets]
        
        facets.inject(hash) do |hash, facet|
          unless facet.name == :class && !options[:class_facet]
            options[:group_by]    = facet.attribute_name
            hash.add_from_results facet, search(*(args + [options]))
          end
          
          hash
        end
      end
      
      def facets_for_all_models(args, options)
        options = GlobalFacetOptions.merge(options)
        hash    = ThinkingSphinx::FacetCollection.new args + [options]
        options = options.merge! facet_query_options
        
        facet_names(options).inject(hash) do |hash, name|
          options[:group_by] = name
          hash.add_from_results name, search(*(args + [options]))
          hash
        end
      end
      
      def facet_query_options
        config = ThinkingSphinx::Configuration.instance
        max    = config.configuration.searchd.max_matches || 1000
        
        {
          :group_function => :attr,
          :limit          => max,
          :max_matches    => max,
          :page           => 1
        }
      end
      
      def facet_classes(options)
        options[:classes] || ThinkingSphinx.indexed_models.collect { |model|
          model.constantize
        }
      end
      
      def facet_names(options)
        classes = facet_classes(options)
        names   = options[:all_attributes] ?
          facet_names_for_all_classes(classes) :
          facet_names_common_to_all_classes(classes)
        
        names.delete "class_crc" unless options[:class_facet]
        names
      end
      
      def facet_names_for_all_classes(classes)
        all_facets = classes.collect { |klass| klass.sphinx_facets }.flatten
        
        all_facets.group_by { |facet|
          facet.name
        }.collect { |name, facets|
          if facets.collect { |facet| facet.type }.uniq.length > 1
            raise "Facet #{name} exists in more than one model with different types"
          end
          facets.first.attribute_name
        }
      end
      
      def facet_names_common_to_all_classes(classes)
        facet_names_for_all_classes(classes).select { |name|
          classes.all? { |klass|
            klass.sphinx_facets.detect { |facet|
              facet.attribute_name == name
            }
          }
        }
      end
    end
  end
end