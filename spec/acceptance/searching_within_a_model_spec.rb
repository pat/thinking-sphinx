# encoding: UTF-8
require 'acceptance/spec_helper'

describe 'Searching within a model', :live => true do
  it "returns results" do
    article = Article.create! :title => 'Pancakes'
    index

    Article.search.first.should == article
  end

  it "returns results matching the given query" do
    pancakes = Article.create! :title => 'Pancakes'
    waffles  = Article.create! :title => 'Waffles'
    index

    articles = Article.search 'pancakes'
    articles.should include(pancakes)
    articles.should_not include(waffles)
  end

  it "handles unicode characters" do
    istanbul = City.create! :name => 'İstanbul'
    index

    City.search('İstanbul').to_a.should == [istanbul]
  end
end
