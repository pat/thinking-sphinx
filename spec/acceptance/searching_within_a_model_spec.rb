require 'spec_helper'

describe 'Searching within a model', :live => true, :wip => true do
  it "returns results" do
    Article.create! :title => 'Pancakes'

    ThinkingSphinx::Configuration.instance.controller.index

    articles = Article.search

    articles.populate
    articles.length.should == 1
    articles.first.should be_an(Article)
  end
end
