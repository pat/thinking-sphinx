class ThinkingSphinx::Masks::GroupEnumeratorsMask
  def initialize(search)
    @search = search
  end

  def can_handle?(method)
    public_methods(false).include?(method)
  end

  def each_with_count(&block)
    @search.raw.each_with_index do |row, index|
      yield @search[index], row[ThinkingSphinx::SphinxQL.count[:column]]
    end
  end

  def each_with_group(&block)
    @search.raw.each_with_index do |row, index|
      yield @search[index], row[ThinkingSphinx::SphinxQL.group_by[:column]]
    end
  end

  def each_with_group_and_count(&block)
    @search.raw.each_with_index do |row, index|
      yield @search[index], row[ThinkingSphinx::SphinxQL.group_by[:column]],
        row[ThinkingSphinx::SphinxQL.count[:column]]
    end
  end
end
