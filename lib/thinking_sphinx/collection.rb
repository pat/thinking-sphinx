module ThinkingSphinx
  class Collection < ::Array
    attr_reader :total_entries, :total_pages, :current_page, :per_page
    attr_accessor :results

    # Compatibility with older versions of will_paginate
    alias_method :page_count, :total_pages
    
    def initialize(page, per_page, entries, total_entries)
      @current_page, @per_page, @total_entries = page, per_page, total_entries
      
      @total_pages = (entries / @per_page.to_f).ceil
    end
    
    def self.ids_from_results(results, page, limit, options)
      collection = self.new(page, limit,
        results[:total] || 0, results[:total_found] || 0
      )
      collection.results = results
      collection.replace results[:matches].collect { |match|
        match[:attributes]["sphinx_internal_id"]
      }
      return collection
    end
    
    def self.create_from_results(results, page, limit, options)
      collection = self.new(page, limit,
        results[:total] || 0, results[:total_found] || 0
      )
      collection.results = results
      collection.replace instances_from_matches(results[:matches], options)
      return collection
    end
    
    def self.instances_from_matches(matches, options = {})
      if klass = options[:class]
        index_options = klass.sphinx_index_options

        ids = matches.collect { |match| match[:attributes]["sphinx_internal_id"] }
        instances = ids.length > 0 ? klass.find(
          :all,
          :conditions => {klass.primary_key.to_sym => ids},
          :include    => (options[:include] || index_options[:include]),
          :select     => (options[:select] || index_options[:select])
        ) : []

        # Raise an exception if we find records in Sphinx but not in the DB, so the search method
        # can retry without them. See ThinkingSphinx::Search.retry_search_on_stale_index.
        if options[:raise_on_stale] && instances.length < ids.length
          stale_ids = ids - instances.map {|i| i.id }
          raise StaleIdsException, stale_ids
        end

        ids.collect { |obj_id|
          instances.detect { |obj| obj.id == obj_id }
        }
      else
        # Group results by class and call #find(:all) once for each group
        # to reduce the number of #find's in multi-model searches
        groups = matches.group_by { |match| match[:attributes]["class_crc"] }
        groups.each do |crc, group|
          group.replace(instances_from_matches(group, options.update(:class => class_from_crc(crc))))
        end
        
        matches.collect do |match|
          groups.detect { |crc, group| crc == match[:attributes]["class_crc"] }[1].
            detect { |obj| obj.id == match[:attributes]["sphinx_internal_id"] }
        end
      end
    end
    
    def self.class_from_crc(crc)
      @@models_by_crc ||= ThinkingSphinx.indexed_models.inject({}) do |hash, model|
        hash[model.constantize.to_crc32] = model
        model.constantize.subclasses.each { |subclass|
          hash[subclass.to_crc32] = subclass.name
        }
        hash
      end
      @@models_by_crc[crc].constantize
    end
    
    def previous_page
      current_page > 1 ? (current_page - 1) : nil
    end
    
    def next_page
      current_page < total_pages ? (current_page + 1): nil
    end
    
    def offset
      (current_page - 1) * @per_page
    end
    
    def method_missing(method, *args, &block)
      super unless method.to_s[/^each_with_.*/]
      
      each_with_attribute method.to_s.gsub(/^each_with_/, ''), &block
    end
    
    def each_with_group_and_count(&block)
      results[:matches].each_with_index do |match, index|
        yield self[index], match[:attributes]["@group"], match[:attributes]["@count"]
      end
    end
    
    def each_with_attribute(attribute, &block)
      results[:matches].each_with_index do |match, index|
        yield self[index], (match[:attributes][attribute] || match[:attributes]["@#{attribute}"])
      end
    end
    
    def each_with_weighting(&block)
      results[:matches].each_with_index do |match, index|
        yield self[index], match[:weight]
      end
    end
  end
end