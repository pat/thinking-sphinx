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
        :group_by => facet,
        :indices  => index_names_for(facet)
      )
      batch.searches << search
    end

    batch.populate

    batch.searches.each do |search|
      key = search.options[:group_by]

      @hash[key.to_sym] = search.raw.inject({}) { |set, row|
        set[row[key]] = row['@count']
        set
      }
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
    @facets ||= indices.collect(&:facets).flatten
  end

  def index_names_for(facet)
    indices.select { |index| index.facets.include?(facet) }.collect &:name
  end

  def indices
    @indices ||= ThinkingSphinx::IndexSet.new options[:classes],
      options[:indices]
  end
end
