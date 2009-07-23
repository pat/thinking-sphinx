# encoding: UTF-8
When /^I search for the specific id of (\d+) in the (\w+) index$/ do |id, index|
  @id     = id.to_i
  @index  = index
end

When /^I search for the document id of (\w+) (\w+) in the (\w+) index$/ do |model, name, index|
  model   = model.gsub(/\s/, '_').camelize.constantize
  @id     = model.find_by_name(name).sphinx_document_id
  @index  = index
end

Then "it should exist" do
  ThinkingSphinx::Search.search_for_id(@id, @index).should == true
end

Then "it should not exist" do
  ThinkingSphinx::Search.search_for_id(@id, @index).should == false
end

Then "it should exist if using Rails 2.1 or newer" do
  require 'active_record/version'
  unless ActiveRecord::VERSION::STRING.to_f < 2.1
    ThinkingSphinx::Search.search_for_id(@id, @index).should == true
  end
end

Then "it should not exist if using Rails 2.1 or newer" do
  require 'active_record/version'
  unless ActiveRecord::VERSION::STRING.to_f < 2.1
    ThinkingSphinx::Search.search_for_id(@id, @index).should == false
  end
end

Then /^I can iterate by result and group and count$/ do
  results.each_with_groupby_and_count do |result, group, count|
    result.should be_kind_of(@model)
    count.should  be_kind_of(Integer)
    group.should  be_kind_of(Integer)
  end
end

Then "each result id should match the corresponding sphinx internal id" do
  results.each_with_sphinx_internal_id do |result, id|
    result.id.should == id
  end
end

Then "I should have an array of integers" do
  results.each do |result|
    result.should be_kind_of(Integer)
  end
end

Then "searching for ids should match the record ids of the normal search results" do
  normal_results = results
  
  # reset search, switch method
  @results = nil
  @method  = :search_for_ids
  
  results.to_a.should == normal_results.collect(&:id)
end

Then /^I should get a value of (\d+)$/ do |count|
  results.should == count.to_i
end

Then /^the (\w+) excerpt of the first result is "(.*)"$/ do |column, string|
  excerpt = results.excerpt_for(results.first.send(column))
  if excerpt.respond_to?(:force_encoding)
    excerpt = excerpt.force_encoding('UTF-8')
  end
  
  excerpt.should == string
end

Then /^calling (\w+) on the first result excerpts object should return "(.*)"$/ do |column, string|
  excerpt = results.first.excerpts.send(column)
  if excerpt.respond_to?(:force_encoding)
    excerpt = excerpt.force_encoding('UTF-8')
  end
  
  excerpt.should == string
end
