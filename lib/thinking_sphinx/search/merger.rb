class ThinkingSphinx::Search::Merger
  def initialize(search)
    @search = search
  end

  def merge!(query = nil, options = {})
    @search.query = query unless query.nil?
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
