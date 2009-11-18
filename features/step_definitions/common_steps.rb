Before do
  $queries_executed = []
  
  @model      = nil
  @method     = :search
  @query      = ""
  @conditions = {}
  @with       = {}
  @without    = {}
  @with_all   = {}
  @options    = {}
  @results    = nil
  
  Given "updates are enabled"
end

Given /^I am searching on (.+)$/ do |model|
  @model = model.gsub(/\s/, '_').singularize.camelize.constantize
end

Given /^updates are (\w+)$/ do |action|
  ThinkingSphinx.updates_enabled = (action == "enabled")
end

When /^I am searching for ids$/ do
  @results = nil
  @method = :search_for_ids
end

When /^I use index (.+)$/ do |index|
  @results = nil
  @options[:index] = index
end

When /^I am retrieving the result count$/ do
  @result = nil
  @method = @model ? :search_count : :count
end

When /^I search$/ do
  @results = nil
end

When /^I search for (\w+)$/ do |query|
  @results = nil
  @query = query
end

When /^I search for "([^\"]*)"$/ do |query|
  @results = nil
  @query = query
end

When /^I search for (\w+) on (\w+)$/ do |query, field|
  @results = nil
  @conditions[field.to_sym] = query
end

When /^I output the raw result data$/ do
  puts results.results.inspect
end

When /^I clear existing filters$/ do
  @with     = {}
  @without  = {}
  @with_all = {}
end

When /^I filter by (\w+) on (\w+)$/ do |filter, attribute|
  @results = nil
  @with[attribute.to_sym] = filter.to_i
end

When /^I filter by (\d+) and (\d+) on (\w+)$/ do |value_one, value_two, attribute|
  @results = nil
  @with[attribute.to_sym] = [value_one.to_i, value_two.to_i]
end

When /^I filter by both (\d+) and (\d+) on (\w+)$/ do |value_one, value_two, attribute|
  @results = nil
  @with_all[attribute.to_sym] = [value_one.to_i, value_two.to_i]
end

When /^I filter between ([\d\.]+) and ([\d\.]+) on (\w+)$/ do |first, last, attribute|
  @results = nil
  if first[/\./].nil? && last[/\./].nil?
    @with[attribute.to_sym] = first.to_i..last.to_i
  else
    @with[attribute.to_sym] = first.to_f..last.to_f
  end
end

When /^I filter between (\d+) and (\d+) days ago on (\w+)$/ do |last, first, attribute|
  @results = nil
  @with[attribute.to_sym] = first.to_i.days.ago..last.to_i.days.ago
end

When /^I filter by (\w+) between (\d+) and (\d+)$/ do |attribute, first, last|
  @results = nil
  @with[attribute.to_sym] = Time.utc(first.to_i)..Time.utc(last.to_i)
end

When /^I order by (\w+)$/ do |attribute|
  @results = nil
  @options[:order] = attribute.to_sym
end

When /^I order by "([^\"]+)"$/ do |str|
  @results = nil
  @options[:order] = str
end

When /^I group results by the (\w+) attribute$/ do |attribute|
  @results = nil
  @options[:group_function] = :attr
  @options[:group_by]       = attribute
end

When /^I set match mode to (\w+)$/ do |match_mode|
  @results = nil
  @options[:match_mode] = match_mode.to_sym
end

When /^I set per page to (\d+)$/ do |per_page|
  @results = nil
  @options[:per_page] = per_page.to_i
end

When /^I set retry stale to (\w+)$/ do |retry_stale|
  @results = nil
  @options[:retry_stale] = case retry_stale
  when "true"  then true
  when "false" then false
  else retry_stale.to_i
  end
end

When /^I destroy (\w+) (\w+)$/ do |model, name|
  model.gsub(/\s/, '_').camelize.
    constantize.find_by_name(name).destroy
end

Then /^the (\w+) of each result should indicate order$/ do |attribute|
  results.inject(nil) do |prev, current|
    unless prev.nil?
      current.send(attribute.to_sym).should >= prev.send(attribute.to_sym)
    end
    
    current
  end
end

Then /^I can iterate by result and (\w+)$/ do |attribute|
  iteration = lambda { |result, attr_value|
    result.should be_kind_of(@model)
    unless attribute == "group" && attr_value.nil?
      attr_value.should be_kind_of(Integer)
    end
  }
  
  results.send("each_with_#{attribute}", &iteration)
end

Then /^I should get (\d+) results?$/ do |count|
  results.length.should == count.to_i
end

Then /^I should not get (\d+) results?$/ do |count|
  results.length.should_not == count.to_i
end

Then /^I should get as many results as there are (.+)$/ do |model|
  results.length.should == model.gsub(/\s/, '_').singularize.camelize.
    constantize.count
end

def results
  @results ||= (@model || ThinkingSphinx).send(
    @method,
    @query,
    @options.merge(
      :conditions => @conditions,
      :with       => @with,
      :without    => @without,
      :with_all   => @with_all
    )
  )
end
