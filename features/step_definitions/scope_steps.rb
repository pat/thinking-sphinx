When /^I use the ([\w]+) scope$/ do |scope|
  @results = results.send(scope.to_sym)
end

When /^I use the ([\w]+) scope set to "([^\"]*)"$/ do |scope, value|
  @results = results.send(scope.to_sym, value)
end

When /^I use the ([\w]+) scope set to (\d+)$/ do |scope, int|
  @results = results.send(scope.to_sym, int.to_i)
end

When /^I am retrieving the scoped result count$/ do
  @results = results.search_count
end

When /^I am retrieving the scoped result count for "([^"]*)"$/ do |query|
  @results = results.search_count query
end
