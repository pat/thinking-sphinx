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
end
