When /^I change the name of alpha (\w+) to (\w+)$/ do |current, replacement|
  Alpha.find_by_name(current).update_attributes(:name => replacement)
end