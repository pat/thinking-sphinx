When /^I destroy gamma (\w+) without callbacks$/ do |name|
  @results = nil
  gamma = Gamma.find_by_name(name)
  Gamma.delete(gamma.id) if gamma
end

Then "I should get a single result of nil" do
  results.to_a.should == [nil]
end

Then /^I should get a single gamma result with a name of (\w+)$/ do |name|
  results.length.should == 1
  results.first.should be_a(Gamma)
  results.first.name.should == name
end
