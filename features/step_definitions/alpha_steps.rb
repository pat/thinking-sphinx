When /^I create a new alpha named (\w+)$/ do |name|
  Alpha.create!(:name => name, :value => 101)
end

When /^I change the (\w+) of alpha (\w+) to (\w+)$/ do |column, name, replacement|
  Alpha.find_by_name(name).update_attributes(column.to_sym => replacement)
end

When /^I filter by active alphas$/ do
  @results = nil
  @with[:active] = true
end

When /^I flag alpha (\w+) as inactive$/ do |name|
  Alpha.find_by_name(name).update_attributes(:active => false)
end
