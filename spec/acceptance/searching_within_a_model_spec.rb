require 'spec_helper'

describe 'Searching within a model', :live => true, :wip => true do
  it "returns results" do
    articles = Article.search

    articles.should_not be_empty
    articles.each { |article|
      article.should be_an(Article)
    }
  end
end
