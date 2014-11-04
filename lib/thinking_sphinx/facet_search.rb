class ThinkingSphinx::FacetSearch
  include Enumerable

  attr_reader   :options
  attr_accessor :query

  def initialize(query = nil, options = {})
    query, options   = nil, query if query.is_a?(Hash)
    @query, @options = query, options
    @hash             = {}
  end

  def [](key)
    populate

    @hash[key]
  end

  def each(&block)
    populate

    @hash.each(&block)
  end

  def for(facet_values)
    filter_facets = facet_values.keys.collect { |key|
      facets.detect { |facet| facet.name == key.to_s }
    }

    ThinkingSphinx::Search.new query, options.merge(
      :indices => index_names_for(*filter_facets)
    ).merge(Filter.new(facets, facet_values).to_hash)
  end

  def populate
    return if @populated

    batch = ThinkingSphinx::BatchedSearch.new
    facets.each do |facet|
      batch.searches << ThinkingSphinx::Search.new(query, options_for(facet))
    end

    batch.populate ThinkingSphinx::Middlewares::RAW_ONLY

    facets.each_with_index do |facet, index|
      @hash[facet.name.to_sym] = facet.results_from batch.searches[index].raw
    end

    @hash[:class] = @hash[:sphinx_internal_class]

    @populated = true
  end

  def populated?
    @populated
  end

  def to_hash
    populate

    @hash
  end

  private

  def facets
    @facets ||= properties.group_by(&:name).collect { |name, matches|
      ThinkingSphinx::Facet.new name, matches
    }
  end

  def properties
    properties = indices.collect(&:facets).flatten
    if options[:facets].present?
      properties = properties.select { |property|
        options[:facets].include? property.name.to_sym
      }
    end
    properties
  end

  def index_names_for(*facets)
    facet_names(
      indices.select do |index|
        facets.all? { |facet| facet_names(index.facets).include?(facet.name) }
      end
    )
  end

  def facet_names(facets)
    facets.collect(&:name)
  end

  def indices
    @indices ||= ThinkingSphinx::IndexSet.new options[:classes], options[:indices]
  end

  def max_matches
    ThinkingSphinx::Configuration.instance.settings['max_matches'] || 1000
  end

  def limit
    limit = options[:limit] || options[:per_page] || max_matches
  end

  def options_for(facet)
    options.merge(
      :select      => [(options[:select] || '*'),
        "#{ThinkingSphinx::SphinxQL.group_by[:select]}",
        "#{ThinkingSphinx::SphinxQL.count[:select]}"
      ].join(', '),
      :group_by    => facet.name,
      :indices     => index_names_for(facet),
      :max_matches => max_matches,
      :limit       => limit
    )
  end

  class Filter
    def initialize(facets, hash)
      @facets, @hash = facets, hash
    end

    def to_hash
      @hash.keys.inject({}) { |options, key|
        type = @facets.detect { |facet| facet.name == key.to_s }.filter_type
        options[type] ||= {}
        options[type][key] = @hash[key]
        options
      }
    end
  end
end
