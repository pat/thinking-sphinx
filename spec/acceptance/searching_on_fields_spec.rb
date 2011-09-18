require 'spec_helper'

describe 'Searching on fields', :live => true do
  it "limits results by field" do
    pancakes = Article.create! :title => 'Pancakes'
    waffles  = Article.create! :title => 'Waffles',
      :content => 'Different to pancakes - and not quite as tasty.'
    index

    articles = Article.search :conditions => {:title => 'pancakes'}
    articles.should include(pancakes)
    articles.should_not include(waffles)
  end

  it "limits results for a field from an association" do
    user     = User.create! :name => 'Pat'
    pancakes = Article.create! :title => 'Pancakes', :user => user
    index

    Article.search(:conditions => {:user => 'pat'}).first.should == pancakes
  end

  it "returns results with matches from concatenated field results" do
    user     = User.create! :name => 'Pat'
    pancakes = Article.create! :title => 'Pancakes', :user => user
    waffles  = Article.create! :title => 'Waffles',  :user => user
    index

    Article.search('waffles', :conditions => {:title => 'pancakes'}).to_a.
      should == [pancakes]
  end
end
