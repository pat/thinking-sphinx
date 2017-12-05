# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Executing multiple searches in one Sphinx call', :live => true do
  it "returns results matching the given queries" do
    pancakes = Article.create! :title => 'Pancakes'
    waffles  = Article.create! :title => 'Waffles'
    index

    batch = ThinkingSphinx::BatchedSearch.new
    batch.searches << Article.search('pancakes')
    batch.searches << Article.search('waffles')

    batch.populate

    expect(batch.searches.first).to include(pancakes)
    expect(batch.searches.first).not_to include(waffles)

    expect(batch.searches.last).to include(waffles)
    expect(batch.searches.last).not_to include(pancakes)
  end
end
