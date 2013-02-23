class ThinkingSphinx::Masks::WeightEnumeratorMask
  def initialize(search)
    @search = search
  end

  def can_handle?(method)
    public_methods(false).include?(method)
  end

  def each_with_weight(&block)
    @search.raw.each_with_index do |row, index|
      yield @search[index], row['@weight']
    end
  end
end
