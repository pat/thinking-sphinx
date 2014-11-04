class ThinkingSphinx::Search::Merger
  attr_reader :search

  def initialize(search)
    @search = search
  end

  def merge!(query = nil, options = {})
    if search.populated?
      raise ThinkingSphinx::PopulatedResultsError, 'This search request has already been made - you can no longer modify it.'
    end

    query, options = nil, query if query.is_a?(Hash)
    @search.query  = query unless query.nil?

    options.each do |key, value|
      case key
      when :conditions, :with, :without, :with_all, :without_all
        @search.options[key] ||= {}
        @search.options[key].merge! value
      when :without_ids, :classes
        @search.options[key] ||= []
        @search.options[key] += value
        @search.options[key].uniq!
      else
        @search.options[key] = value
      end
    end

    @search
  end
end
