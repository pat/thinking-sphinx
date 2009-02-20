When /I change the name of extensible beta (\w+) to (\w+)$/ do |current, replacement|
  ExtensibleBeta.find_by_name(current).update_attributes(:name => replacement)
end

Then /^the generic delta handler should handle the delta indexing$/ do
  ExtensibleBeta.find(:first, :conditions => {:changed_by_generic => true}).should_not be_nil
end