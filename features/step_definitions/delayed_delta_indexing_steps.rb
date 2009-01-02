When /^I run the delayed jobs$/ do
  Delayed::Job.work_off.inspect
end

When /^I change the name of delayed beta (\w+) to (\w+)$/ do |current, replacement|
  DelayedBeta.find_by_name(current).update_attributes(:name => replacement)
end
