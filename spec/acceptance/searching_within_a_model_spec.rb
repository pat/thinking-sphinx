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

  it "can search on namespaced models" do
    person = Admin::Person.create :name => 'James Bond'
    index

    Admin::Person.search('Bond').to_a.should == [person]
  end

  it "raises an error if searching through an ActiveRecord scope" do
    lambda {
      City.ordered.search
    }.should raise_error(ThinkingSphinx::MixedScopesError)
  end

  it "does not raise an error when searching with a default ActiveRecord scope" do
    lambda {
      User.search
    }.should_not raise_error(ThinkingSphinx::MixedScopesError)
  end

  it "raises an error when searching with default and applied AR scopes" do
    lambda {
      User.recent.search
    }.should raise_error(ThinkingSphinx::MixedScopesError)
  end

  it "raises an error if the model has no indices defined" do
    lambda {
      Category.search.to_a
    }.should raise_error(ThinkingSphinx::NoIndicesError)
  end
end

describe 'Searching within a model with a realtime index', :live => true do
  it "returns results" do
    product = Product.create! :name => 'Widget'

    Product.search.first.should == product
  end
end
