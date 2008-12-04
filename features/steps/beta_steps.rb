When /^I destroy beta (\w+)$/ do |name|
  Beta.find_by_name(name).destroy
end

When /^I create a new beta named (\w+)$/ do |name|
  Beta.create(:name => name)
end

When /^I change the name of beta (\w+) to (\w+)$/ do |current, replacement|
  Beta.find_by_name(current).update_attributes(:name => replacement)
end