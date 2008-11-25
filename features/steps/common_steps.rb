Before do
  @model      = nil
  @query      = ""
  @conditions = {}
  @with       = {}
  @without    = {}
  @order      = nil
end

Given /I am searching on (\w+)/ do |model|
  @model = model.singularize.camelize.constantize
end

When /^I search for (\w+)$/ do |query|
  @query = query
end

When /^I search for (\w+) on (\w+)$/ do |query, field|
  @conditions[field.to_sym] = query
end

When /^I filter by (\w+) on (\w+)$/ do |filter, attribute|
  @with[attribute.to_sym] = filter.to_i
end

When /^I order by (\w+)$/ do |attribute|
  @order = attribute.to_sym
end

Then /^the (\w+) of each result should indicate order$/ do |attribute|
  results.inject(nil) do |prev, current|
    unless prev.nil?
      current.send(attribute.to_sym).should >= prev.send(attribute.to_sym)
    end
    
    current
  end
end

Then /^I should get (\d+) results?$/ do |count|
  results.length.should == count.to_i
end

def results
  @results ||= (@model || ThinkingSphinx::Search).search(
    @query,
    :conditions => @conditions,
    :with       => @with,
    :without    => @without,
    :order      => @order
  )
end