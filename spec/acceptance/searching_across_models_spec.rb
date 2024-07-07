# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Searching across models', :live => true do
  it "returns results" do
    article = Article.create! :title => 'Pancakes'
    index

    expect(ThinkingSphinx.search.first).to eq(article)
  end

  it "returns results matching the given query" do
    pancakes = Article.create! :title => 'Pancakes'
    waffles  = Article.create! :title => 'Waffles'
    index

    articles = ThinkingSphinx.search 'pancakes'
    expect(articles).to include(pancakes)
    expect(articles).not_to include(waffles)
  end

  it "handles results from different models" do
    article = Article.create! :title => 'Pancakes'
    book    = Book.create! :title => 'American Gods'
    index

    expect(ThinkingSphinx.search.to_a).to match_array([article, book])
  end

  it "filters by multiple classes" do
    article = Article.create! :title => 'Pancakes'
    book    = Book.create! :title => 'American Gods'
    user    = User.create! :name => 'Pat'
    index

    expect(ThinkingSphinx.search(:classes => [User, Article]).to_a).
      to match_array([article, user])
  end

  it "has a 'none' default scope" do
    article = Article.create! :title => 'Pancakes'
    index

    expect(ThinkingSphinx.none).to be_empty
  end
end
