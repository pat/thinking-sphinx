# encoding: UTF-8
# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Searching within a model', :live => true do
  it "returns results" do
    article = Article.create! :title => 'Pancakes'
    index

    expect(Article.search.first).to eq(article)
  end

  it "returns results matching the given query" do
    pancakes = Article.create! :title => 'Pancakes'
    waffles  = Article.create! :title => 'Waffles'
    index

    articles = Article.search 'pancakes'
    expect(articles).to include(pancakes)
    expect(articles).not_to include(waffles)
  end

  it "handles unicode characters" do
    istanbul = City.create! :name => 'İstanbul'
    index

    expect(City.search('İstanbul').to_a).to eq([istanbul])
  end

  it "will star provided queries on request" do
    article = Article.create! :title => 'Pancakes'
    index

    expect(Article.search('cake', :star => true).first).to eq(article)
  end

  it "allows for searching on specific indices" do
    article = Article.create :title => 'Pancakes'
    index

    articles = Article.search('pancake', :indices => ['stemmed_article_core'])
    expect(articles.to_a).to eq([article])
  end

  it "allows for searching on distributed indices" do
    article = Article.create :title => 'Pancakes'
    index

    articles = Article.search('pancake', :indices => ['article'])
    expect(articles.to_a).to eq([article])
  end

  it "can search on namespaced models" do
    person = Admin::Person.create :name => 'James Bond'
    index

    expect(Admin::Person.search('Bond').to_a).to eq([person])
  end

  it "raises an error if searching through an ActiveRecord scope" do
    expect {
      City.ordered.search
    }.to raise_error(ThinkingSphinx::MixedScopesError)
  end

  it "does not raise an error when searching with a default ActiveRecord scope" do
    expect {
      User.search
    }.not_to raise_error
  end

  it "raises an error when searching with default and applied AR scopes" do
    expect {
      User.recent.search
    }.to raise_error(ThinkingSphinx::MixedScopesError)
  end

  it "raises an error if the model has no indices defined" do
    expect {
      Category.search.to_a
    }.to raise_error(ThinkingSphinx::NoIndicesError)
  end

  it "handles models with alternative id columns" do
    album = Album.create! :name => 'The Seldom Seen Kid', :artist => 'Elbow'
    index

    expect(Album.search.first).to eq(album)
  end
end

describe 'Searching within a model with a realtime index', :live => true do
  it "returns results" do
    product = Product.create! :name => 'Widget'

    expect(Product.search.first).to eq(product)
  end
end
