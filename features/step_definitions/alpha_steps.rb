When /^I change the (\w+) of alpha (\w+) to (\w+)$/ do |column, name, replacement|
  Alpha.find_by_name(name).update_attributes(column.to_sym => replacement)
end