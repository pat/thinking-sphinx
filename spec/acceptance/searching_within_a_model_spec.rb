require 'spec_helper'

describe 'Searching within a model', :live => true do
  it "returns results" do
    Article.create! :title => 'Pancakes'

    ThinkingSphinx::Configuration.instance.controller.index
    sleep 0.25

    articles = Article.search

    articles.populate
    articles.length.should == 1
    articles.first.should be_an(Article)
  end
end
