When /^I destroy cat (\w+)$/ do |name|
  Cat.find_by_name(name).destroy
end