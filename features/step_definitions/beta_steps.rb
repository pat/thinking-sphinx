When /^I create a new beta named (\w+)$/ do |name|
  Beta.create!(:name => name, :value => 101)
end

When /^I change the (\w+) of beta (\w+) to (\w+)$/ do |column, name, replacement|
  Beta.find_by_name(name).update_attributes(column.to_sym => replacement)
end
