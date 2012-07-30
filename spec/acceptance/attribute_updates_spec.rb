require 'acceptance/spec_helper'

describe 'Update attributes automatically where possible', :live => true do
  it "updates boolean values" do
    article = Article.create :title => 'Pancakes', :published => false
    index

    Article.search('pancakes', :with => {:published => true}).should be_empty

    article.published = true
    article.save

    Article.search('pancakes', :with => {:published => true}).to_a
      .should == [article]
  end
end
