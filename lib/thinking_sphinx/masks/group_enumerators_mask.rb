# frozen_string_literal: true

class ThinkingSphinx::Masks::GroupEnumeratorsMask
  def initialize(search)
    @search = search
  end

  def can_handle?(method)
    public_methods(false).include?(method)
  end

  def each_with_count(&block)
    @search.raw.each_with_index do |row, index|
      yield @search[index], row["sphinx_internal_count"]
    end
  end

  def each_with_group(&block)
    @search.raw.each_with_index do |row, index|
      yield @search[index], row["sphinx_internal_group"]
    end
  end

  def each_with_group_and_count(&block)
    @search.raw.each_with_index do |row, index|
      yield @search[index], row["sphinx_internal_group"],
        row["sphinx_internal_count"]
    end
  end
end
