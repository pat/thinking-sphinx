When "I am requesting facet results$" do
  @method = :facets
end

When "I am requesting facet results with classes included" do
  @method = :facets
  @options = {}
  @options[:include_class_facets] = true
end

When /^I drill down where (\w+) is (\w+)$/ do |facet, value|
  @results = results.for(facet.downcase.to_sym => value)
end

When /^I drill down where (\w+) is (\w+) and (\w+) is (\w+)$/ do |facet_one, value_one, facet_two, value_two|
  value_one = value_one.to_i unless value_one[/^\d+$/].nil?
  value_two = value_two.to_i unless value_two[/^\d+$/].nil?
  
  @results = results.for(
    facet_one.downcase.to_sym => value_one,
    facet_two.downcase.to_sym => value_two
  )
end

When /^I drill down where ([\w_]+) includes the id of tag (\w+)$/ do |facet, text|
  tag = Tag.find_by_text(text)
  @results = results.for(facet.downcase.to_sym => tag.id)
end

Then "I should have valid facet results" do
  results.should be_kind_of(Hash)
  results.values.each { |value| value.should be_kind_of(Hash) }
end

Then /^I should have (\d+) facets?$/ do |count|
  results.keys.length.should == count.to_i
end

Then /^I should have the facet ([\w_\s]+)$/ do |name|
  results[name.gsub(/\s/, '').underscore.to_sym].should be_kind_of(Hash)
end

Then /^the ([\w_\s]+) facet should have a "([\w\s_]+)" key with (\d+) hits$/ do |name, key, hit_count|
  facet_name = name.gsub(/\s/, '').underscore.to_sym
  results[facet_name].keys.should include(key)
  results[facet_name][key].should eql(hit_count.to_i)
end

Then /^the ([\w_\s]+) facet should have a "(\w+)" key$/ do |name, key|
  facet_name = name.gsub(/\s/, '').underscore.to_sym
  results[facet_name].keys.should include(key)
end
