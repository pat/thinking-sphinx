require 'acceptance/spec_helper'

describe 'Hiding deleted records from search results', :live => true do
  it "does not return deleted records" do
    pancakes = Article.create! :title => 'Pancakes'
    index

    Article.search('pancakes').should_not be_empty
    pancakes.destroy

    Article.search('pancakes').should be_empty
  end
end
