require 'acceptance/spec_helper'

describe 'Searching for just instance Ids', :live => true do
  it "returns just the instance ids" do
    pancakes = Article.create! :title => 'Pancakes'
    waffles  = Article.create! :title => 'Waffles'
    index

    Article.search_for_ids('pancakes').to_a.should == [pancakes.id]
  end

  it "works across the global context" do
    article = Article.create! :title => 'Pancakes'
    book    = Book.create! :title => 'American Gods'
    index

    ThinkingSphinx.search_for_ids.to_a.should =~ [article.id, book.id]
  end
end
