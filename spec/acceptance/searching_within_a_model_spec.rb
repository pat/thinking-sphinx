require 'spec_helper'

describe 'Searching within a model', :live => true do
  it "returns results" do
    index do
      Article.create! :title => 'Pancakes'
    end

    articles = Article.search

    articles.populate
    articles.length.should == 1
    articles.first.should be_an(Article)
  end
end
