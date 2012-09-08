class ThinkingSphinx::FacetSearch
  attr_reader :query, :options

  def initialize(query = nil, options = {})
    query, options   = nil, query if query.is_a?(Hash)
    @query, @options = query, options
    @hash             = {}
  end

  def [](key)
    populate

    @hash[key]
  end

  def populate
    return if @populated

    batch = ThinkingSphinx::BatchedSearch.new
    facets.each do |facet|
      search = ThinkingSphinx::Search.new query, options.merge(
        :group_by => facet.name,
        :indices  => index_names_for(facet)
      )
      batch.searches << search
    end

    batch.populate

    facets.each_with_index do |facet, index|
      @hash[facet.name.to_sym] = facet.results_from batch.searches[index].raw
    end

    @hash[:class] = @hash[:sphinx_internal_class]

    @populated = true
  end

  def to_hash
    populate

    @hash
  end

  private

  def facets
    @facets ||= begin
      properties = indices.collect(&:facets).flatten
      properties.group_by(&:name).collect { |name, matches|
        ThinkingSphinx::Facet.new name, matches
      }
    end
  end

  def index_names_for(facet)
    indices.select { |index|
      index.facets.collect(&:name).include?(facet.name)
    }.collect &:name
  end

  def indices
    @indices ||= ThinkingSphinx::IndexSet.new options[:classes],
      options[:indices]
  end
end
