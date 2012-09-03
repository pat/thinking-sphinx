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
      batch.searches << ThinkingSphinx::Search.new(query, options.merge(:group_by => facet))
    end

    batch.populate

    batch.searches.each do |search|
      @hash[search.options[:group_by].to_sym] = search.raw.inject({}) { |set, row|
        set[row['@groupby']] = row['@count']
        set
      }
    end

    @populated = true
  end

  def to_hash
    populate

    @hash
  end

  private

  def facets
    indices.collect(&:facets).flatten
  end

  def indices
    @indices ||= ThinkingSphinx::IndexSet.new options[:classes],
      options[:indices]
  end
end
