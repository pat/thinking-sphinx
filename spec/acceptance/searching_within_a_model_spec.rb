require 'spec_helper'

describe 'Searching within a model', :live => true do
  it "returns results" do
    article = nil
    index do
      article = Article.create! :title => 'Pancakes'
    end

    Article.search.first.should == article
  end
end
