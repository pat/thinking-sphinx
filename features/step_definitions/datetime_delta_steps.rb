When /^I index the theta datetime delta$/ do
  Theta.sphinx_indexes.first.delta_object.delayed_index(Theta)
end

When /^I change the name of theta (\w+) to (\w+)$/ do |current, replacement|
  Theta.find_by_name(current).update_attributes(:name => replacement)
end

When /^I create a new theta named (\w+)$/ do |name|
  Theta.create(:name => name)
end
