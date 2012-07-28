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

  it "will star provided queries on request" do
    article = Article.create! :title => 'Pancakes'
    index

    Article.search('cake', :star => true).first.should == article
  end

  it "allows for searching on specific indices" do
    article = Article.create :title => 'Pancakes'
    index

    articles = Article.search('pancake', :indices => ['stemmed_article_core'])
    articles.to_a.should == [article]
  end
end

describe 'Searching within a model with a realtime index', :live => true do
  it "returns results" do
    pending "Sphinx bug on OS X means I can't currently test this."
    product = Product.create! :name => 'Widget'

    Product.search.first.should == product
  end
end
