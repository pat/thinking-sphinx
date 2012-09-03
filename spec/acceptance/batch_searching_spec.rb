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

    batch.searches.first.should include(pancakes)
    batch.searches.first.should_not include(waffles)

    batch.searches.last.should include(waffles)
    batch.searches.last.should_not include(pancakes)
  end
end
