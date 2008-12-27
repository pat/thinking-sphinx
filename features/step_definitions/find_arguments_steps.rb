When "I include comments" do
  @results = nil
  @options[:include] = :comments
end

When /^I get the first comment$/ do
  @comment = Comment.find(:first)
end

When /^I track queries$/ do
  $queries_executed = []
end

When /^I compare comments$/ do
  results.first.comments.first.should == @comment
end

When /^I select only content$/ do
  @results = nil
  @options[:select] = "id, content"
end

Then /^I should have (\d+) quer[yies]+$/ do |count|
  $queries_executed.length.should == count.to_i
end

Then /^I should not get an error accessing the subject$/ do
  lambda { results.first.subject }.should_not raise_error
end

Then /^I should get an error accessing the subject$/ do
  error_class = NoMethodError
  error_class = ActiveRecord::MissingAttributeError if ActiveRecord.constants.include?("MissingAttributeError")
  
  lambda { results.first.subject }.should raise_error(error_class)
end
