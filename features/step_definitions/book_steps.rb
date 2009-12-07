When /^I destroy the book titled "([^\"]*)"$/ do |title|
  Book.first(:title => title).destroy
end

When /^I change the title of "([^\"]*)" to "([^\"]*)"$/ do |title, value|
  Book.first(:title => title).update(:title => value)
end
