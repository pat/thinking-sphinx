When "I am requesting facet results" do
  @method = :facets
end

Then "I should see facet results" do
  results.should be_kind_of(Hash)
  results.values.each { |value| value.should be_kind_of(Hash) }
end